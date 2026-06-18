---
title: POP3 메일 수집과 DB 저장
description: ""
date: 2026-06-19T11:00:00.000Z
preview: ""
draft: true
tags:
    - Python
    - POP3
    - 이메일
    - DB
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

# 개요

POP3로 메일함에 접속해 새 메일을 읽고, DB에 저장하는 파이프라인이다.
1편의 **계정 목록 순회 + 외부 호출 + 결과 기록**에, MIME 파싱과 증분 동기화가 추가된다.

계정·서버는 데모용이며, 비밀번호는 환경 변수로만 전달한다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

# 처리 흐름

```
accounts.txt → POP3 접속 → 최신 메일부터 역순 조회
    ↓
DB에 이미 있는 시점 이전 메일이면 중단
    ↓
헤더·본문 파싱 → INSERT → log.txt 기록
```

IMAP과 달리 POP3는 기본적으로 서버에서 메일을 가져오기만 한다. 메일함 설정에서 POP3 사용이 활성화되어 있어야 한다.

---

# POP3 접속

SSL(포트 995)이 일반적이다. `poplib.POP3_SSL`로 연결한다.

```python
import poplib

def connect_pop3(host: str, user: str, password: str) -> poplib.POP3_SSL:
    client = poplib.POP3_SSL(host, port=995)
    client.user(user)
    client.pass_(password)
    return client
```

호스트 예: `pop.example.com`. `accounts.txt`에는 줄당 메일 주소(아이디) 하나만 둔다.
비밀번호는 `MAIL_PW_<계정>` 환경 변수로 읽는다 (`user@example.com` → `MAIL_PW_user_example_com`).

```python
import os

def mail_password_env_key(mail_id: str) -> str:
    return "MAIL_PW_" + mail_id.replace("@", "_").replace(".", "_")

def get_mail_password(mail_id: str) -> str | None:
    return os.getenv(mail_password_env_key(mail_id))
```

---

# 메일 개수와 역순 조회

`stat()`으로 전체 메시지 수를 얻고, 번호가 큰 쪽이 최신이다.

```python
def iter_messages(client: poplib.POP3_SSL):
    total = client.stat()[0]
    for num in range(total, 0, -1):
        yield num, client.retr(num)[1]
```

최신부터 내려가며, 이미 DB에 저장된 시점에 도달하면 루프를 끊는다.

---

# MIME 헤더 디코딩

제목·발신자 등은 `=?UTF-8?B?...?=` 형태로 인코딩되어 있다.
`email` 모듈과 base64·quoted-printable 디코딩으로 복원한다.

```python
import email
import quopri
import base64
import re

def decode_header_value(raw: str) -> str:
    parts = re.findall(r"(=\?[^?]+\?[BQbq]\?[^?]*\?=)", raw)
    if not parts:
        return raw
    decoded = []
    for part in parts:
        body = part[2:-2]  # =? 제거
        charset, enc, text = body.split("?", 2)
        if enc.upper() == "B":
            text = base64.b64decode(text).decode(charset)
        else:
            text = quopri.decodestring(text.encode()).decode(charset)
        decoded.append(text)
    return "".join(decoded)
```

여러 조각으로 쪼개진 헤더(`=?UTF-8?B?...?= =?UTF-8?B?...?=`)는 순서대로 이어 붙인다.

---

# 메시지 파싱

`email.message_from_bytes`로 객체를 만들고 헤더·본문을 추출한다.

```python
from datetime import datetime

def parse_message(raw_lines: list[bytes]) -> dict:
    msg = email.message_from_bytes(b"\n".join(raw_lines))
    subject = decode_header_value(msg.get("Subject", ""))
    mail_from = decode_header_value(msg.get("From", ""))
    date_str = msg.get("Date", "")
    body = extract_text_body(msg)
    return {
        "subject": subject,
        "mail_from": mail_from,
        "mail_date": parse_mail_date(date_str),
        "content_text": body,
    }
```

`parse_mail_date`는 `email.utils.parsedate_to_datetime`으로 통일하는 것이 간단하다.

---

# 본문 추출 (multipart)

`multipart` 메일은 `walk()`로 파트를 순회한다. `text/plain`을 우선한다.

```python
def extract_text_body(msg: email.message.Message) -> str:
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                payload = part.get_payload(decode=True)
                charset = part.get_content_charset() or "utf-8"
                return payload.decode(charset, errors="replace")
        return ""
    payload = msg.get_payload(decode=True)
    charset = msg.get_content_charset() or "utf-8"
    return payload.decode(charset, errors="replace")
```

첨부 파일은 `Content-Disposition: attachment`인 파트의 파일명·바이너리를 별도 컬럼이나 스토리지에 저장한다.

---

# 증분 동기화

DB에 저장된 **해당 계정의 최신 메일 시각**을 조회하고, 그 이전 메일이 나오면 수집을 중단한다.

```python
def get_latest_stored_time(mail_id: str) -> datetime:
    # DB에서 MAX(mail_date) 조회. 없으면 과거 기본값
    row = db_query("SELECT MAX(mail_date) FROM mails WHERE mail_id = ?", (mail_id,))
    if row and row[0]:
        return datetime.fromisoformat(row[0])
    return datetime(2000, 1, 1)

def should_stop(mail_date: datetime, latest_stored: datetime) -> bool:
    return mail_date <= latest_stored
```

최신부터 역순으로 읽기 때문에, 중단 조건이 성립하면 이미 저장된 메일에 도달한 것이다.

---

# DB INSERT

파라미터 바인딩으로 INSERT한다. 본문에 따옴표가 있어도 안전하다.

```python
import sqlite3

def insert_mail(conn, mail_id: str, data: dict) -> None:
    conn.execute(
        """INSERT INTO mails
           (mail_id, mail_from, subject, mail_date, content_text)
           VALUES (?, ?, ?, ?, ?)""",
        (
            mail_id,
            data["mail_from"],
            data["subject"],
            data["mail_date"].isoformat(),
            data["content_text"],
        ),
    )
    conn.commit()
```

원격 DB는 환경 변수 `DATABASE_URL` 등으로 연결한다. 중복 방지를 위해 `(mail_id, message_id)` UNIQUE 제약을 두는 것이 좋다.

---

# 계정 순회 (최소)

```python
import os
from pathlib import Path

def run_once() -> int:
    success = 0
    accounts = Path("accounts.txt").read_text(encoding="utf-8").splitlines()
    for line in accounts:
        if not line.strip() or line.startswith("#"):
            continue
        mail_id = line.strip()
        mail_pw = get_mail_password(mail_id)
        if not mail_pw:
            print(f"[skip] {mail_id}: password env not set")
            continue
        latest = get_latest_stored_time(mail_id)
        client = connect_pop3("pop.example.com", mail_id, mail_pw)
        for num, raw in iter_messages(client):
            data = parse_message(raw)
            if should_stop(data["mail_date"], latest):
                break
            insert_mail(conn, mail_id, data)
            success += 1
        client.quit()
    return success
```

`accounts.txt` 예시 — 줄당 주소 하나:

```
user@example.com
```

실행 후 `log.txt`에 `시각\t저장 건수`를 append한다.

---

# 로그

```python
from datetime import datetime

def append_log(path: str, count: int) -> None:
    with open(path, "a", encoding="utf-8") as f:
        f.write(f"{datetime.now():%Y-%m-%d %H:%M:%S}\t{count}\n")
```

---

# 주의사항

- **POP3 설정** — 메일 서비스에서 POP3/SMTP 사용 허용 필요
- **비밀번호** — `accounts.txt`에는 주소만. 비밀번호는 환경 변수. 둘 다 git에 올리지 않음
- **대용량 첨부** — `poplib._MAXLINE` 기본값 초과 시 상향 (예: 20480)
- **IMAP 대안** — 폴더·읽음 상태·검색이 필요하면 IMAP + `imaplib` 검토
- **인코딩** — 깨진 헤더는 `errors="replace"`로 fallback

---
