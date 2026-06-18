---
title: Selenium 검색 순위 모니터링
description: ""
date: 2026-06-20T10:00:00.000Z
preview: ""
draft: true
tags:
    - Python
    - Selenium
    - 크롤링
    - 모니터링
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

# 개요

키워드로 검색한 결과 페이지(SERP)에서 특정 URL이 몇 위에 노출되는지 주기적으로 확인하는 패턴이다.
JavaScript 렌더링·동적 DOM이 필요한 경우 **Selenium WebDriver**로 브라우저를 직접 조작한다.

1편의 **목록 순회 → 외부 호출 → 결과 저장 → 반복**에, 브라우저 자동화와 CSS 셀렉터 매칭이 추가된다.
키워드·URL은 데모용이며, 실서비스 값은 넣지 않는다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

# 처리 흐름

```
targets.txt (키워드\tURL)
    ↓
각 행: WebDriver로 검색 URL 접속
    ↓
결과 목록 CSS 셀렉터 순회 → href 매칭 → 순위
    ↓
DB upsert 또는 TSV 출력
    ↓
delay 후 반복
```

HTTP만으로 HTML을 받을 수 없거나, 무한 스크롤·지연 로딩이 있으면 Selenium이 필요하다. 8편은 requests 기반 대안을 다룬다.

---

# WebDriver 세팅

헤드리스 Chrome이 배치에 흔하다. `webdriver-manager`로 드라이버 경로를 자동 관리할 수 있다.

```bash
pip install selenium webdriver-manager
```

```python
from selenium import webdriver
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
    return webdriver.Chrome(service=service, options=options)
```

`--disable-dev-shm-usage`는 Linux 컨테이너에서 Chrome이 죽는 경우를 줄인다.

---

# 셀렉터 상수 분리

검색 엔진은 DOM 클래스명을 자주 바꾼다. 셀렉터를 코드 상단·config에 모아 두면 수정 지점이 한곳으로 모인다.

```python
RESULT_ITEM = "article.search-result"      # 결과 한 줄
RESULT_LINK = "a.result-link"              # 제목 링크
NO_RESULT = "div.no-results"               # 결과 없음
```

실제 사이트에 맞게 값을 바꾼다. 블로그 글에는 **가상의 클래스명**만 쓴다.

---

# 순위 조회

검색 URL에 키워드를 넣고, 결과 링크를 위에서부터 순회하며 목표 URL과 비교한다.

```python
from urllib.parse import quote_plus
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

SEARCH_URL = "https://search.example.com?q={keyword}"

def find_rank(driver, keyword: str, target_url: str, max_rank: int = 30) -> int | str:
    driver.get(SEARCH_URL.format(keyword=quote_plus(keyword)))
    try:
        WebDriverWait(driver, 20).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, RESULT_ITEM))
        )
    except Exception:
        if driver.find_elements(By.CSS_SELECTOR, NO_RESULT):
            return "0"
        raise

    links = driver.find_elements(By.CSS_SELECTOR, RESULT_LINK)
    for rank, elem in enumerate(links[:max_rank], start=1):
        href = elem.get_attribute("href") or ""
        if target_url in href or href in target_url:
            return rank
    return "0"
```

`max_rank`로 상위 N위까지만 본다. 미발견은 `"0"` 또는 `"0,0"` 같은 관례 문자열로 DB에 기록하기도 한다.

---

# 드라이버 복구

타임아웃·차단 페이지가 나오면 세션을 버리고 새 드라이버를 만든다.

```python
def refresh_driver(driver) -> webdriver.Chrome:
    try:
        driver.quit()
    except Exception:
        pass
    return create_driver()
```

요청 간 `time.sleep(2)`를 두거나, IP·프록시 로테이션을 쓰는 운영도 있다. 과도한 호출은 차단·ToS 위반으로 이어질 수 있다.

---

# 한 사이클

```python
from pathlib import Path

def load_targets(path: str) -> list[tuple[str, str]]:
    rows = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        keyword, url = line.split("\t")
        rows.append((keyword.strip(), url.strip()))
    return rows

def run_once(driver, targets: list[tuple[str, str]]) -> list[dict]:
    results = []
    for keyword, url in targets:
        try:
            rank = find_rank(driver, keyword, url)
            results.append({"keyword": keyword, "url": url, "rank": rank})
            print(f"{keyword}: rank={rank}")
        except Exception as e:
            print(f"[error] {keyword}: {e}")
            driver = refresh_driver(driver)
    return results
```

개별 키워드 실패 시 드라이버만 갱신하고 다음 행을 계속 처리한다.

---

# DB upsert

같은 키워드·URL 조합은 순위·확인일만 갱신한다. SQLite 예시:

```python
import sqlite3
from datetime import datetime

def upsert_rank(conn, row: dict) -> None:
    conn.execute(
        """INSERT INTO serp_ranks (keyword, url, rank, checked_at)
           VALUES (?, ?, ?, ?)
           ON CONFLICT(keyword, url) DO UPDATE SET
             rank = excluded.rank,
             checked_at = excluded.checked_at""",
        (row["keyword"], row["url"], str(row["rank"]), datetime.now().isoformat()),
    )
    conn.commit()
```

`ON CONFLICT`는 UNIQUE `(keyword, url)` 제약이 있을 때 동작한다.

---

# 입력 파일

`targets.txt` — 탭 구분:

```
python tutorial	https://example.com/docs/python
web scraping guide	https://example.com/blog/scraping
```

---

# Selenium vs HTTP (8편)

| | Selenium (현재) | requests + BS4 (8편) |
|--|-----------------|----------------------|
| JS 렌더링 | 지원 | 미지원(정적 HTML만) |
| 리소스 | 무거움(브라우저) | 가벼움 |
| 병렬 | 프로세스당 드라이버 1개 권장 | multiprocessing에 유리 |
| 유지보수 | 셀렉터·드라이버 버전 | URL·HTML 구조 |

---

# 주의사항

- **robots.txt·이용 약관** — 자동화 허용 범위 확인
- **셀렉터 깨짐** — DOM 변경 시 상수만 교체하는 습관
- **헤드리스 탐지** — 일부 사이트는 headless를 막음. 필요 시 headed + 가상 디스플레이
- **동시성** — WebDriver는 스레드 안전하지 않음. 키워드 병렬은 프로세스별 드라이버

---
