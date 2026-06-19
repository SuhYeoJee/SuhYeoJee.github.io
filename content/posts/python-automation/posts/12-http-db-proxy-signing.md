---
title: Python — HTTP DB 프록시와 요청 서명
description: ""
date: 2026-06-18T16:00:00.000Z
preview: ""
draft: false
tags:
    - Python
    - HTTP
    - DB
    - API
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

## 개요

배치 PC가 DB에 **직접 연결하지 않고**, 웹 서버의 HTTP API를 통해 SELECT·INSERT를 수행하는 패턴이다.

9편 TSV는 로컬 파일에서 대상 목록을 읽는다. 이 글은 **원격 DB 앞단의 HTTP 게이트웨이** — 방화벽·자격 증명·페이징 — 를 다룬다.

데모 URL·테이블명만 사용하며, 실서비스 엔드포인트는 넣지 않는다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.
**본인이 관리하는 서버·DB API**에만 적용한다.

---

## 처리 흐름

```
배치 PC (Python requests)
    ↓
POST /api/db  { timestamp, signature, action, payload }
    ↓
서버: 서명 검증 → SQL 실행 → JSON 응답
    ↓
배치: 결과 파싱 → 다음 페이지 / INSERT
```

DB 포트(3306 등)를 인터넷에 열지 않아도 된다.

---

## 9편과의 위치

| 편 | 저장소 접근 |
|----|-------------|
| 9편 | 로컬 SQLite / 파일 TSV |
| 12편 (현재) | **HTTP API → 서버 측 DB** |

9편으로 `targets`를 쌓은 뒤, 원격 DB에 올릴 때 이 API를 쓰는 파이프라인이 가능하다.

---

## 요청 서명

클라이언트가 보낸 요청이 위·변조되지 않았음을 서버가 확인한다. 단순 패턴은 **timestamp + 공유 salt → 해시**다.

```python
import hashlib
import os
import time

def make_signature() -> tuple[int, str]:
    salt = os.getenv("API_SALT")
    if not salt:
        raise RuntimeError("API_SALT not set")
    ts = int(time.time() * 1000)
    raw = f"{ts}{salt}".encode("utf-8")
    sig = hashlib.sha256(raw).hexdigest()
    return ts, sig
```

서버는 동일 방식으로 해시를 재계산해 비교한다. salt는 `os.getenv("API_SALT")`로만 읽는다.

---

## SELECT 페이징

대량 행은 `LIMIT` / `OFFSET`으로 나눠 받는다.

```python
import requests

API_URL = "https://api.example.com/db"  # 데모

def db_select_page(limit: int = 1000, offset: int = 0) -> list[dict]:
    ts, sig = make_signature()
    resp = requests.post(
        API_URL,
        json={
            "timestamp": ts,
            "signature": sig,
            "action": "select",
            "table": "targets",
            "limit": limit,
            "offset": offset,
        },
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json().get("rows", [])

def db_select_all(page_size: int = 1000) -> list[dict]:
    rows: list[dict] = []
    offset = 0
    while True:
        batch = db_select_page(limit=page_size, offset=offset)
        if not batch:
            break
        rows.extend(batch)
        offset += page_size
    return rows
```

빈 배열이 오면 마지막 페이지로 본다.

---

## INSERT / upsert

```python
def db_upsert(row: dict) -> None:
    ts, sig = make_signature()
    resp = requests.post(
        API_URL,
        json={
            "timestamp": ts,
            "signature": sig,
            "action": "upsert",
            "table": "batch_results",
            "data": row,
        },
        timeout=30,
    )
    resp.raise_for_status()
```

서버는 `ON DUPLICATE KEY UPDATE` 등으로 upsert를 구현한다. **raw SQL 문자열을 클라이언트에서 보내는 방식**은 SQL injection 위험이 있어, 블로그·신규 설계에서는 `action` + 구조화된 `data`만 권장한다.

---

## 서버 측 검증 (개념)

서버(PHP, FastAPI 등)에서 수행할 일:

1. `timestamp`가 현재 시각 ±5분 이내인지 (replay 방지)
2. `signature`가 salt로 재계산한 값과 일치하는지
3. `action`별 허용 테이블·컬럼 화이트리스트
4. 파라미터 바인딩으로 SQL 실행

클라이언트에 DB URL·비밀번호를 두지 않는다.

---

## 오류 처리

```python
def db_request(payload: dict) -> dict | list:
    ts, sig = make_signature()
    payload = {**payload, "timestamp": ts, "signature": sig}
    resp = requests.post(API_URL, json=payload, timeout=30)
    if resp.status_code != 200:
        raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:200]}")
    body = resp.json()
    if body.get("error"):
        raise RuntimeError(body["error"])
    return body.get("rows") or body.get("data")
```

HTTP 상태·JSON `error` 필드를 구분해 로그에 남긴다.

---

## 다운스트림 배치 예시

```
9편 TSV ingest (로컬)  ──HTTP upsert──►  원격 DB (targets)
후속 배치              ◄──HTTP select──  원격 DB (targets)
                       ──HTTP upsert──►  원격 DB (batch_results)
```

배치 PC는 `requests`만 있으면 되고, DB 드라이버 설치가 필요 없다.
후속 배치는 HTTP·Selenium·LLM 등 임의 작업이 될 수 있다.

---

## 주의사항

- **raw SQL POST** — 레거시에 있을 수 있으나 신규에는 비권장
- **HTTPS** — 서명·데이터 노출 방지
- **salt 유출** — 환경 변수·서버만 보관, git 제외
- **장애** — API 다운 시 배치는 재시도·로컬 큐 적재 고려

---
