---
title: Python — subprocess 격리와 timeout
description: ""
date: 2026-06-18T15:30:00.000Z
preview: ""
draft: false
tags:
    - Python
    - subprocess
    - timeout
    - 배치
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

## 개요

외부 라이브러리 호출이 **hang**하거나 메모리를 잡아먹을 때, 작업을 **별도 프로세스**로 분리하고 `communicate(timeout=)`으로 시간 상한을 두는 패턴이다.

4편 Google Play 수집은 메인 프로세스에서 스크래퍼를 직접 호출한다. 이 글은 그 앞뒤에 붙는 **운영·안정성 레이어** — 격리 실행, timeout, kill, 재시도 — 를 다룬다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## 처리 흐름

```
메인 루프 (목록 순회)
    ↓
subprocess.Popen(worker.py, item)
    ↓
communicate(timeout=N) → stdout 파싱
    ↓
TimeoutExpired → kill → 재시도 (상한)
    ↓
다음 항목
```

자식 프로세스가 죽어도 부모 배치는 계속 돌아간다.

---

## 왜 격리하는가

| 문제 | subprocess 격리 효과 |
|------|---------------------|
| 특정 입력에서 무한 대기 | timeout 후 kill, 다음 항목 진행 |
| 네이티브/라이브러리 메모리 누수 | 프로세스 종료 시 OS가 회수 |
| segfault·크래시 | 자식만 종료, 부모는 살아 있음 |
| GIL과 무관한 CPU 작업 | 별도 프로세스에서 실행 |

스크래핑·이미지 처리·무거운 SDK 호출에 자주 쓴다.

---

## worker 스크립트 (자식)

한 항목만 처리하고 **stdout에 결과만** 남긴다. JSON 한 줄이 파싱하기 쉽다.

```python
# worker.py — 데모
import json
import sys
import time

def fetch(item: str) -> dict:
    time.sleep(1)  # 실제: 스크래핑·API 호출
    return {"item": item, "value": 42}

if __name__ == "__main__":
    item = sys.argv[1]
    print(json.dumps(fetch(item)), flush=True)
```

`flush=True`는 버퍼링 때문에 부모가 stdout을 못 읽는 경우를 줄인다.

---

## 부모: Popen + timeout

```python
import json
import subprocess
import time

def run_isolated(item: str, timeout: int = 30, max_retries: int = 3) -> dict:
    for attempt in range(max_retries):
        proc = subprocess.Popen(
            ["python", "worker.py", item],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        try:
            stdout, stderr = proc.communicate(timeout=timeout)
            if proc.returncode != 0:
                raise RuntimeError(stderr or f"exit {proc.returncode}")
            return json.loads(stdout)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.communicate()  # 좀비 방지
            if attempt + 1 >= max_retries:
                raise TimeoutError(f"timeout after {max_retries} tries: {item}")
            time.sleep(10)
    raise RuntimeError("unreachable")
```

`TimeoutExpired` 후에는 반드시 `kill()`과 남은 `communicate()`로 자식을 정리한다.

---

## base64 래핑 (선택)

stdout에 바이너리·특수문자가 섞이면 base64로 감싸 전달한다.

```python
import base64
import json

# 자식
payload = json.dumps(result).encode("utf-8")
print(base64.b64encode(payload).decode("ascii"), flush=True)

# 부모
raw = base64.b64decode(stdout.strip())
result = json.loads(raw.decode("utf-8"))
```

4편에서 worker를 분리할 때 stdout을 base64로 감싸 받는 방식도 쓸 수 있다.

---

## 한 사이클

```python
def run_once(items: list[str]) -> None:
    for item in items:
        try:
            data = run_isolated(item, timeout=30)
            print(f"OK {item}: {data}")
            save_result(data)
        except Exception as e:
            print(f"[error] {item}: {e}")
            log_error(item, e)
```

개별 실패가 루프 전체를 멈추지 않게 `try/except`로 감싼다.

---

## timeout·재시도 설계

| 파라미터 | 역할 |
|----------|------|
| `timeout` | 한 번의 자식 실행 상한(초) |
| `max_retries` | timeout·일시 오류 재시도 횟수 |
| `sleep` between retries | 차단·rate limit 완화 |

timeout을 너무 짧으면 정상 응답도 잘리고, 너무 길면 hang 항목이 큐를 막는다. config에 두는 것이 좋다.

---

## 4편과 합치기

4편 `fetch_app_info(package)` 본문을 `worker.py`로 옮기고, 메인은 패키지 목록만 순회하며 `run_isolated(pkg)`를 호출하면 된다.

```
apps.txt → run_isolated(app.py, pkg) → JSON → DB/TSV
```

직접 호출 대비 프로세스 생성 오버헤드는 있지만, 대량·장시간 배치에서 **한 건 hang이 전체를 멈추지 않는** 이점이 크다.

---

## 주의사항

- Windows spawn — worker도 `if __name__ == "__main__"` 가드
- **pickle·공유 메모리 없음** — 인자는 argv·stdin·파일로만 전달
- 보안 — `shell=True` 지양, `item`에 셸 메타문자 주입 방지
- 로그 — stderr를 `error.log`에 남겨 자식 실패 원인 추적

---
