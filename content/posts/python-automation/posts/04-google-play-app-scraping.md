---
title: Google Play 앱 메트릭 수집
description: ""
date: 2026-06-19T10:00:00.000Z
preview: ""
draft: true
tags:
    - Python
    - Google Play
    - 스크래핑
    - 모니터링
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

# 개요

앱 스토어 페이지에서 다운로드 수·별점·리뷰 정보를 주기적으로 수집해 DB나 파일에 기록하는 패턴이다.
1편의 **목록 순회 + 외부 호출 + 결과 저장 + 반복** 골격에, 스크래핑 라이브러리와 리뷰 필터링이 추가된다.

패키지명·앱 정보는 데모용이며, 실서비스 값은 넣지 않는다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

# 처리 흐름

```
apps.txt (패키지명 목록)
    ↓
각 패키지: google_play_scraper로 앱·리뷰 조회
    ↓
기준일 이후 리뷰 수·미답변 수 집계
    ↓
DB INSERT 또는 TSV 출력
    ↓
delay_minutes 후 반복
```

스토어 페이지 구조 변경에 취약하므로, 공식 API가 없는 영역에서는 라이브러리 버전 고정과 오류 로그가 중요하다.

---

# 앱 메타데이터 조회

`google-play-scraper`는 비공식 라이브러리로, 패키지명만으로 앱 상세 정보를 dict로 반환한다.

```bash
pip install google-play-scraper
```

```python
from google_play_scraper import app

def fetch_app_info(package_name: str) -> dict:
    result = app(package_name, lang="ko", country="kr")
    return {
        "title": result.get("title"),
        "developer": result.get("developer"),
        "real_installs": result.get("realInstalls"),
        "score": result.get("score"),
        "reviews_count": result.get("reviews"),
        "updated": result.get("updated"),
    }
```

`lang`·`country`는 스토어 지역에 맞게 설정한다. 패키지가 없으면 예외가 발생하므로 `try/except`로 건너뛰거나 삭제 목록에 기록한다.

---

# 리뷰 조회와 기준일 필터

`reviews()`는 페이지 단위로 리뷰를 가져온다. `continuation_token`으로 다음 페이지를 이어 받을 수 있다.

```python
from datetime import datetime
from google_play_scraper import reviews, Sort

def fetch_reviews_since(package_name: str, since: datetime, max_count: int = 200):
    result, token = reviews(
        package_name,
        lang="ko",
        country="kr",
        sort=Sort.NEWEST,
        count=max_count,
    )
    filtered = []
    for r in result:
        if r["at"] < since:
            break
        filtered.append(r)
    return filtered
```

기준일(`since`)보다 오래된 리뷰가 나오면 순회를 중단한다. `Sort.NEWEST`이면 최신부터 내려가므로 이 패턴이 효율적이다.

---

# 미답변 리뷰 집계

개발자 답글이 없는 리뷰(`replyContent is None`)를 카운트하는 예시다.

```python
def count_unreplied(review_list: list[dict]) -> tuple[int, int]:
    total = len(review_list)
    unreplied = sum(1 for r in review_list if r.get("replyContent") is None)
    return total, unreplied
```

기준일 이후 리뷰만 대상으로 하려면, 위 `fetch_reviews_since` 결과에 이 함수를 적용하면 된다.

---

# 한 사이클

패키지 목록을 순회하며 메타데이터와 리뷰 통계를 수집한다.

```python
from pathlib import Path
from datetime import datetime, timedelta

SINCE = datetime.now() - timedelta(days=30)

def run_once(packages: list[str]) -> None:
    for pkg in packages:
        try:
            info = fetch_app_info(pkg)
            review_list = fetch_reviews_since(pkg, SINCE)
            total, unreplied = count_unreplied(review_list)
            print(f"{pkg}: {info['title']} installs={info['real_installs']} "
                  f"reviews={total} unreplied={unreplied}")
            save_row(pkg, info, total, unreplied)
        except Exception as e:
            print(f"[error] {pkg}: {e}")
```

`save_row`는 DB INSERT 또는 TSV append로 구현한다. 개별 패키지 실패가 전체 사이클을 멈추지 않게 한다.

---

# DB 저장 (최소)

SQLite로 로컬에 쌓는 경우:

```python
import sqlite3

def save_row(pkg: str, info: dict, review_cnt: int, unreplied: int) -> None:
    conn = sqlite3.connect("play_metrics.db")
    conn.execute(
        """INSERT INTO metrics
           (package, title, installs, review_cnt, unreplied, collected_at)
           VALUES (?, ?, ?, ?, ?, datetime('now'))""",
        (pkg, info["title"], info["real_installs"], review_cnt, unreplied),
    )
    conn.commit()
    conn.close()
```

원격 MySQL 등은 1편·2편과 같이 SSH 터널 또는 DB URL 환경 변수로 연결한다. SQL은 파라미터 바인딩을 써서 문자열 조립 인젝션을 피한다.

---

# 주기 실행

24시간 모니터링은 `config.ini`의 `delay_minutes`와 `while True` 루프로 구현한다.

```python
import configparser
import time

config = configparser.ConfigParser()
config.read("config.ini", encoding="utf-8")
delay = int(config["monitor"]["delay_minutes"]) * 60

packages = Path("apps.txt").read_text(encoding="utf-8").splitlines()

while True:
    run_once([p.strip() for p in packages if p.strip()])
    time.sleep(delay)
```

`apps.txt` — 줄당 패키지명 하나:

```
com.example.demo1
com.example.demo2
```

---

# 타임아웃·격리 (선택)

스크래핑 호출이 hang될 수 있으면, subprocess로 별도 프로세스에 넘기고 `communicate(timeout=N)`으로 제한한다.
타임아웃 시 프로세스를 kill하고 재시도 횟수 상한을 둔다.

```python
import subprocess

def fetch_with_timeout(package: str, timeout: int = 30) -> dict:
    proc = subprocess.run(
        ["python", "fetch_one.py", package],
        capture_output=True, text=True, timeout=timeout,
    )
    proc.check_returncode()
    import json
    return json.loads(proc.stdout)
```

메인 루프와 스크래퍼를 분리하면 한 앱에서 멈춰도 프로세스 단위로 끊을 수 있다.

---

# 주의사항

- **이용 약관** — 스토어 ToS·robots 정책 확인. 과도한 요청은 IP 차단될 수 있다
- **라이브러리 의존** — 페이지 구조 변경 시 `google-play-scraper` 업데이트 필요
- **요청 간격** — 패키지마다 `time.sleep(1)` 등으로 rate limit 완화
- **삭제된 앱** — 조회 실패 패키지는 `remove.txt` 등에 기록해 다음 사이클에서 skip

---
