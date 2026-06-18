---
title: TSV 입력 채널과 DB 증분 적재
description: ""
date: 2026-06-20T11:00:00.000Z
preview: ""
draft: false
tags:
    - Python
    - TSV
    - DB
    - ETL
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

# 개요

스프레드시트·외부 목록을 **TSV(탭 구분)** 파일로 받아 DB에 넣는 입력 채널 패턴이다.
운영팀·시트에서 내려받은 목록을 DB `targets` 테이블에 쌓아 두고, **별도 배치**가 `SELECT`로 읽어 처리하는 구성이 흔하다.

전량 INSERT가 아니라 **이미 있는 행은 건너뛰는 증분 적재**가 핵심이다.
데모 데이터만 사용하며, 실서비스 URL·계정은 넣지 않는다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.
**본인이 관리·접근 권한이 있는 데이터**에만 적용한다.

---

# 처리 흐름

```
스프레드시트 → TSV보내기 → ingest 폴더
    ↓
TSV 파싱·필터(조건 컬럼)
    ↓
DB에 없는 키만 INSERT
    ↓
(다운스트림) 다른 배치가 DB에서 SELECT
```

이 편은 **파일/시트**를 입력 채널로 쓴다. 6편 POP3·메일 파싱과는 별개다.

---

# TSV 읽기

폴더 안 `.tsv`를 모두 읽고, 인코딩 fallback을 둔다.

```python
from pathlib import Path

def read_tsv_lines(folder: str) -> list[str]:
    lines: list[str] = []
    for path in Path(folder).glob("*.tsv"):
        for encoding in ("utf-8", "cp949"):
            try:
                text = path.read_text(encoding=encoding)
                break
            except UnicodeDecodeError:
                continue
        else:
            raise ValueError(f"encoding failed: {path}")
        lines.extend(ln for ln in text.splitlines() if ln.strip())
    return lines
```

구글 시트는 「다운로드 → TSV」로보낸 뒤 `ingest/`에 둔다. API 연동(`gspread`)은 인증 설정이 필요해 배치 파일 방식이 단순하다.

---

# 행 파싱

헤더가 있으면 첫 줄을 컬럼명으로 쓴다. 데모는 탭 고정 컬럼이다.

```python
def parse_row(line: str, headers: list[str] | None = None) -> dict:
    cols = line.split("\t")
    if headers:
        return dict(zip(headers, cols))
    # 데모: keyword, url, category, view_count
    return {
        "keyword": cols[0].strip(),
        "url": cols[1].strip(),
        "category": cols[2].strip() if len(cols) > 2 else "",
        "view_count": cols[3].strip() if len(cols) > 3 else "0",
    }
```

필터 조건 예: `category == "target"`인 행만 DB에 넣는다.

---

# 필터

```python
def should_ingest(row: dict, target_category: str = "target") -> bool:
    return row.get("category") == target_category
```

업무에서는 「특정 태그·상태 컬럼」으로 적재 대상을 좁힌다.

---

# 증분 적재 (존재하면 skip)

자연키 `(keyword, url)` 기준으로 DB에 있으면 INSERT하지 않는다.

```python
import sqlite3

def exists(conn: sqlite3.Connection, keyword: str, url: str) -> bool:
    cur = conn.execute(
        "SELECT 1 FROM targets WHERE keyword = ? AND url = ? LIMIT 1",
        (keyword, url),
    )
    return cur.fetchone() is not None

def insert_target(conn: sqlite3.Connection, row: dict) -> bool:
    if exists(conn, row["keyword"], row["url"]):
        return False
    conn.execute(
        """INSERT INTO targets (keyword, url, category, view_count, created_at)
           VALUES (?, ?, ?, ?, datetime('now'))""",
        (row["keyword"], row["url"], row["category"], row["view_count"]),
    )
    return True
```

`INSERT OR IGNORE` + UNIQUE 제약으로 한 줄로 쓸 수도 있다.

```python
conn.execute(
    """INSERT OR IGNORE INTO targets (keyword, url, category, view_count)
       VALUES (?, ?, ?, ?)""",
    (row["keyword"], row["url"], row["category"], row["view_count"]),
)
```

---

# 한 사이클

```python
def run_ingest(tsv_folder: str, db_path: str, target_category: str = "target") -> tuple[int, int]:
    conn = sqlite3.connect(db_path)
    conn.execute(
        """CREATE TABLE IF NOT EXISTS targets (
           keyword TEXT NOT NULL,
           url TEXT NOT NULL,
           category TEXT,
           view_count TEXT,
           created_at TEXT,
           UNIQUE(keyword, url)
        )"""
    )
    inserted = skipped = 0
    for line in read_tsv_lines(tsv_folder):
        if line.startswith("keyword\t"):
            continue  # 헤더 스킵
        row = parse_row(line)
        if not should_ingest(row, target_category):
            continue
        if insert_target(conn, row):
            inserted += 1
        else:
            skipped += 1
    conn.commit()
    conn.close()
    return inserted, skipped
```

`inserted` / `skipped`를 로그에 남기면 적재량을 추적할 수 있다.

---

# 다운스트림: DB에서 읽기

적재한 `targets`는 후속 배치의 입력으로 쓴다. 파일(`targets.txt`) 대신 DB를 쓰면 시트 수정과 처리를 분리하기 쉽다.

```python
def load_targets_from_db(db_path: str) -> list[tuple[str, str]]:
    conn = sqlite3.connect(db_path)
    rows = conn.execute("SELECT keyword, url FROM targets ORDER BY created_at").fetchall()
    conn.close()
    return [(r[0], r[1]) for r in rows]
```

대량이면 `LIMIT/OFFSET` 페이징을 쓴다. 원격 DB는 [12편](./12-http-db-proxy-signing.md) HTTP SELECT 페이징과 같은 패턴이다.

```python
def load_targets_page(conn, limit: int = 1000, offset: int = 0):
    return conn.execute(
        "SELECT keyword, url FROM targets LIMIT ? OFFSET ?",
        (limit, offset),
    ).fetchall()
```

---

# TSV 예시

`ingest/chart_export.tsv`:

```
keyword	url	category	view_count
python tutorial	https://example.com/a	target	1200
rust guide	https://example.com/b	other	800
web scraping	https://example.com/c	target	450
```

---

# 파이프라인에서의 위치

| 단계 | 역할 |
|------|------|
| 입력 (현재) | TSV → DB `targets` |
| 처리 | DB `targets` → 외부 호출·변환 배치 |
| 출력 | 결과 테이블 upsert 또는 파일 기록 |

9편 없이 `targets.txt`만 써도 되지만, 시트·운영 수정과 배치를 분리하려면 DB 중간층이 유리하다.

---

# 주의사항

- **인코딩** — Excel·시트보내기는 `cp949`인 경우가 많다
- **중복 키** — UNIQUE 설계를 먼저 정한다
- **TSV 내 탭** — 본문에 탭이 들어가면 컬럼이 밀린다. CSV로 바꾸거나 quoting 규칙 통일
- **시트 수동 단계** — 자동화 한계를 인지하고, 필요 시 Sheets API로 대체

---
