---
title: POP3 메일 읽기와 MIME 파싱
description: ""
date: 2026-06-19T11:00:00.000Z
preview: ""
draft: false
tags:
    - Python
    - POP3
    - 이메일
    - MIME
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

## 개요

POP3로 메일함에 접속해 **한 통을 읽고**, `email` 모듈로 헤더·본문을 **파싱**하는 패턴이다.
저장·배치 파이프라인(9·12편)과 분리해, **읽기·디코딩**만 다룬다.

**본인이 접근 권한이 있는 메일함**에서만 적용한다. 데모는 `pop.example.com`·합성 주소를 쓴다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## 처리 흐름

```
POP3 접속 → stat / retr → bytes → email.message_from_bytes
    ↓
헤더 디코딩 → multipart 본문 추출 → 요약 출력
```

로컬 `sample.eml` 파일로 파싱만 연습할 수도 있다. POP3 없이 MIME 구조를 익히기 좋다.

IMAP과 달리 POP3는 기본적으로 서버에서 메일을 가져오기만 한다. 메일함 설정에서 POP3 사용이 활성화되어 있어야 한다.

---

## 로컬 .eml로 파싱 연습

```python
import email
from pathlib import Path

raw = Path("sample.eml").read_bytes()
msg = email.message_from_bytes(raw)
```

합성 샘플로 `Subject`·`From`·`text/plain` 추출을 먼저 검증한 뒤, POP3 `retr` 결과에 같은 함수를 쓴다.

---

## POP3 접속 (단일 계정 데모)

SSL(포트 995)이 일반적이다.

```python
import os
import poplib

def connect_pop3(host: str, user: str, password: str) -> poplib.POP3_SSL:
    client = poplib.POP3_SSL(host, port=995)
    client.user(user)
    client.pass_(password)
    return client

# 데모: 환경 변수에서 읽기
user = os.getenv("MAIL_USER", "user@example.com")
password = os.getenv("MAIL_PASSWORD")
if password:
    client = connect_pop3("pop.example.com", user, password)
```

비밀번호는 코드·git에 넣지 않는다.

---

## 최신 메일 한 통 읽기

```python
def fetch_latest_raw(client: poplib.POP3_SSL) -> list[bytes]:
    total = client.stat()[0]
    if total == 0:
        return []
    _, lines, _ = client.retr(total)
    return lines
```

---

## MIME 헤더 디코딩

제목·발신자 등은 `=?UTF-8?B?...?=` 형태로 인코딩되어 있다.

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
        body = part[2:-2]
        charset, enc, text = body.split("?", 2)
        if enc.upper() == "B":
            text = base64.b64decode(text).decode(charset)
        else:
            text = quopri.decodestring(text.encode()).decode(charset)
        decoded.append(text)
    return "".join(decoded)
```

---

## 메시지 파싱

```python
from email.utils import parsedate_to_datetime

def parse_mail_date(date_str: str):
    if not date_str:
        return None
    return parsedate_to_datetime(date_str)

def parse_message(raw_lines: list[bytes]) -> dict:
    msg = email.message_from_bytes(b"\n".join(raw_lines))
    return {
        "subject": decode_header_value(msg.get("Subject", "")),
        "mail_from": decode_header_value(msg.get("From", "")),
        "mail_date": parse_mail_date(msg.get("Date", "")),
        "content_text": extract_text_body(msg),
    }
```

---

## 본문 추출 (multipart)

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

첨부(`Content-Disposition: attachment`)는 **파일명만 출력**하는 정도로 다루고, 본문 저장·DB 적재는 이 글 범위 밖이다.

```python
def list_attachment_names(msg: email.message.Message) -> list[str]:
    names = []
    for part in msg.walk():
        if part.get_content_disposition() == "attachment":
            names.append(part.get_filename() or "(unnamed)")
    return names
```

---

## 요약 출력

```python
def print_summary(data: dict, attachments: list[str]) -> None:
    print("From:", data["mail_from"])
    print("Subject:", data["subject"])
    print("Date:", data["mail_date"])
    print("Body (first 200 chars):", (data["content_text"] or "")[:200])
    if attachments:
        print("Attachments:", ", ".join(attachments))
```

학습용으로는 **본문 전체를 로그에 남기지 않는** 편이 안전하다.

---

## 진입점 (데모)

```python
if __name__ == "__main__":
    raw = fetch_latest_raw(client)
    if not raw:
        print("No messages")
    else:
        msg = email.message_from_bytes(b"\n".join(raw))
        data = parse_message(raw)
        print_summary(data, list_attachment_names(msg))
    client.quit()
```

---

## 주의사항

- **접근 권한** — 본인 메일함·명시적 허가가 있는 계정만
- **개인정보** — 발신자·본문은 개인정보에 해당할 수 있음. 출력·로그 최소화
- **POP3 설정** — 메일 서비스에서 POP3/SMTP 사용 허용 필요
- **대용량 첨부** — `poplib._MAXLINE` 기본값 초과 시 상향 (예: 20480)
- **IMAP 대안** — 폴더·읽음 상태·검색이 필요하면 IMAP + `imaplib` 검토
- **저장·배치** — DB·TSV 적재는 [9편](./09-tsv-incremental-db-ingest.md)·[12편](./12-http-db-proxy-signing.md) 참고

---
