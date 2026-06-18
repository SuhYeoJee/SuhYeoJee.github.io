---
title: Selenium 멀티프로세싱 패턴
description: ""
date: 2026-06-20T11:30:00.000Z
preview: ""
draft: false
tags:
    - Python
    - Selenium
    - multiprocessing
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

## 개요

Selenium WebDriver는 **프로세스마다 인스턴스를 하나** 두는 것이 안전하다. 드라이버를 스레드 간에 공유하면 세션이 꼬이고, 한 프로세스에 여러 드라이버를 동시에 띄우면 메모리 부담이 크다.

이 글은 **Pool + wrapper + worker** 구조로, 워커 프로세스당 드라이버 1개를 만들고 URL·작업 목록을 청크로 나눠 처리하는 **병렬 브라우저 자동화** 패턴을 정리한다.
순차 Selenium(한 컨트롤러로 목록 순회)과 달리, **입력이 많고 프로세스 격리가 필요할 때** 쓴다.

예제 URL·입력은 데모용이며, 실서비스 값은 넣지 않는다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.
자동화 대상 사이트의 **이용 약관·robots**를 먼저 확인한다.

---

## 처리 흐름

```
input 목록 (URL·키 등)
    ↓
코어 수·청크 크기 계산 → input_data_lst (프로세스별 묶음)
    ↓
Pool.apply_async(wrapper_func, chunk)  × N
    ↓
각 프로세스: create_driver() → worker 반복 → driver.quit()
    ↓
메인: async 결과 수집 → idx 기준 dict 병합 → 출력
```

핵심은 **wrapper가 프로세스 진입점**이고, 그 안에서만 드라이버를 생성·종료한다는 점이다.

---

## 순차 vs 병렬 Selenium

| | 순차 (드라이버 1개) | 병렬 (현재) |
|--|---------------------|-------------|
| 브라우저 | 1개 순회 | 프로세스당 1개 |
| 병렬 | 없음 | `apply_async` + 청크 |
| 메모리 | 낮음 | 코어 수 × Chrome |
| 적합 | 소량·안정 우선 | 대량·격리 필요 |

HTTP만으로 처리 가능하면 `requests` + `multiprocessing.Pool`(8편)이 가볍다. **JS 렌더링이 필요한 작업**만 Selenium을 고른다.

---

## 워커 코어 수 상한

CPU 코어를 그대로 쓰면 Chrome 프로세스가 과도하게 늘어난다. 상한을 둔다.

```python
import multiprocessing

def get_core_count(max_cores: int = 4) -> int:
    n = multiprocessing.cpu_count()
    return min(n, max_cores) if n >= max_cores else n
```

예시로 `max_cores=4`를 상한으로 둔다. 8코어 머신이라도 Pool 크기 4면 Chrome 인스턴스는 최대 4개다.

---

## 청크 크기 계산

`multi_cnt`(Pool에 던지는 작업 수)와 `max_data_cnt`(한 wrapper가 처리할 입력 개수)를 나눠 계산한다.

```python
def split_chunks(total: int, core_cnt: int) -> tuple[int, int]:
    """반환: (max_data_cnt, multi_cnt)"""
    if total < core_cnt:
        max_data_cnt = 1
    elif total > 100 * core_cnt:
        max_data_cnt = 100
    else:
        max_data_cnt = round(total / core_cnt)
    multi_cnt = (total + max_data_cnt - 1) // max_data_cnt
    return max_data_cnt, multi_cnt
```

- 입력이 코어 수보다 적으면 청크 1건씩 — 프로세스가 놀지 않게
- 입력이 매우 많으면 청크당 100건 상한 — wrapper 하나가 너무 오래 잡고 있지 않게
- 그 사이는 `total / core_cnt`로 균등 분배

---

## 입력 묶기

각 행에 **원래 순서 idx**를 붙여 두면, 병렬 처리 후에도 출력 순서를 복원할 수 있다.

```python
def build_input_chunks(input_lst: list[str], max_data_cnt: int, multi_cnt: int):
    input_data = [[idx, line] for idx, line in enumerate(input_lst)]
    chunks = [
        input_data[max_data_cnt * i : max_data_cnt * (i + 1)]
        for i in range(multi_cnt)
    ]
    return chunks
```

`input_data_lst[i]`가 i번째 `apply_async`에 넘어갈 인자 묶음이다.

---

## worker · wrapper 분리

- **worker** — 드라이버와 한 줄 입력으로 실제 작업
- **wrapper** — 프로세스 안에서 드라이버 생성, 청크 순회, 예외 시 드라이버 재생성

```python
from selenium import webdriver

def worker(driver: webdriver.Chrome, input_line: str) -> str:
    driver.get(f"https://example.com/status?id={input_line}")
    # ... DOM 조작·텍스트 추출 ...
    return input_line  # 데모: 입력 그대로 반환

def wrapper_func(chunk: list[list], meta_data: list) -> dict:
    driver = create_driver()
    results = {}
    for idx, input_line in chunk:
        try:
            results[idx] = worker(driver, input_line)
        except Exception:
            driver.quit()
            driver = create_driver()
            try:
                results[idx] = worker(driver, input_line)
            except Exception as e:
                results[idx] = f"err:{e}"
    driver.quit()
    return results
```

한 항목 실패 시 드라이버만 갈아끼우고 재시도한다.
`meta_data`는 공통 설정(URL 템플릿, 셀렉터 dict 등)을 넘길 때 쓴다.

---

## 드라이버 생성 (프로세스 로컬)

wrapper마다 독립 Chrome을 띄운다.

```python
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager

def create_driver(headless: bool = True) -> webdriver.Chrome:
    options = Options()
    if headless:
        options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=options)
    driver.implicitly_wait(10)
    return driver
```

`implicitly_wait`는 요소 탐색 전역 대기. 명시적 `WebDriverWait`와 병용할 수 있다.

---

## Pool 실행과 결과 병합

`apply_async`로 청크별 wrapper를 던지고, 완료된 것부터 `get()`으로 dict를 합친다.

```python
def run_parallel(input_lst: list[str], meta_data: list | None = None) -> dict:
    meta_data = meta_data or []
    core_cnt = get_core_count(4)
    max_data_cnt, multi_cnt = split_chunks(len(input_lst), core_cnt)
    chunks = build_input_chunks(input_lst, max_data_cnt, multi_cnt)

    pool = multiprocessing.Pool(core_cnt)
    async_results = [
        pool.apply_async(wrapper_func, (chunk, meta_data))
        for chunk in chunks
    ]

    merged: dict = {}
    pending = list(async_results)
    while pending:
        for i, ar in enumerate(pending):
            if ar.ready():
                merged.update(ar.get())
                pending.pop(i)
                break

    pool.close()
    pool.join()
    return merged
```

청크 단위로 묶기 때문에 프로세스당 드라이버 1개를 유지하기 쉽다.

---

## 결과 기록 (순서 복원)

병합 dict의 키가 원래 `idx`이므로 입력 순서대로 출력한다.

```python
def write_results(input_lst: list[str], merged: dict) -> None:
    for i, line in enumerate(input_lst):
        val = merged.get(i, "err:missing")
        if str(val).startswith("err:"):
            print(f"[{i+1}] FAIL {line}: {val}")
        else:
            print(f"[{i+1}] OK {line}: {val}")
```

오류 행은 `error.txt`에 append해 재실행 대상만 골라낼 수 있다.

---

## 진입점

Windows에서는 반드시 `if __name__ == "__main__":` 가드 안에서 Pool을 연다.

```python
if __name__ == "__main__":
    items = ["alpha", "beta", "gamma"]  # 또는 input.txt
    results = run_parallel(items, meta_data=["demo"])
    write_results(items, results)
```

가드 없이 import되면 Windows spawn 방식에서 무한 프로세스 생성이 날 수 있다.

---

## 설계 시 주의

| 항목 | 설명 |
|------|------|
| 드라이버 수 | `core_cnt` = 동시 Chrome 수. RAM·GPU 여유 확인 |
| 공유 상태 | 프로세스 간 전역 변수 공유 불가. `meta_data`는 picklable만 |
| 외부 기록 | DB·파일 쓰기는 메인 프로세스에서만 하거나 프로세스별 연결 분리 |
| 좀비 프로세스 | `pool.close()` + `join()` 필수. wrapper에서 `driver.quit()` |
| 디버깅 | 멀티보다 단일 wrapper·단일 worker로 먼저 검증 |
| 약관 | 과도한 요청·허용 범위 밖 자동화 금지 |

---
