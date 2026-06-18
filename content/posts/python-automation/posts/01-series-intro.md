---
title: Python 배치·모니터링 패턴 개요
description: ""
date: 2026-06-18T10:30:00.000Z
preview: ""
draft: false
tags:
    - Python
    - 자동화
    - 배치
    - 모니터링
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

# 개요

Python으로 서버·인프라를 다루는 스크립트는 대부분 같은 골격을 따른다.
**설정 로드 → 대상 순회 → 외부 시스템 호출 → 결과 기록·알림 → 주기적 반복.**

이 시리즈는 그 골격을 기준으로 2~13편 주제를 정리한다.

- **2편** — AWS Lightsail CPU 메트릭 조회와 임계값 알림
- **3편** — SSH + certbot 기반 HTTPS 인증서 자동화
- **4편** — Google Play 앱 메트릭·리뷰 수집
- **5편** — LLM API 배치 텍스트 변환
- **6편** — POP3 메일 읽기와 MIME 파싱
- **7편** — Selenium 기반 검색 순위(SERP) 모니터링
- **8편** — HTTP·BeautifulSoup 검색 순위 조회
- **9편** — TSV 입력 채널과 DB 증분 적재
- **10편** — Selenium 멀티프로세싱 (Pool·wrapper·worker)
- **11편** — subprocess 격리·timeout·재시도
- **12편** — HTTP DB 프록시·요청 서명
- **13편** — PyAutoGUI 데스크톱 입력 자동화

블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

> **면책** — 이 시리즈는 학습·설계 패턴 공유 목적이다. 예제는 데모 URL·합성 데이터만 사용한다. **본인이 접근·관리 권한이 있는 시스템·데이터**에만 적용하고, 제3자 서비스의 이용약관·robots·법령을 준수한다.

아래 스니펫은 이후 글에서 반복 등장하는 기본 블록이다.

---

# 배치 스크립트의 공통 구조

GUI 없이 파일과 로그를 입출력으로 쓰는 스크립트의 전형적인 흐름이다.
크론, systemd timer, Windows 작업 스케줄러에 등록해 상시 실행하는 경우가 많다.

```
config (임계값, 주기, 타임아웃)
    ↓
targets (서버·도메인 목록)
    ↓
for target in targets:
    result = external_call(target)
    if condition(result):
        notify + log
    ↓
sleep(delay) → 반복
```

`external_call` 자리에 AWS CLI, SSH, HTTP API, 스크래핑, LLM API 등이 들어간다. 이후 각 편은 이 자리만 다르다.

---

# 설정 로드

운영 값(임계값, 대기 시간 등)을 코드 밖 `config.ini`에 두면, 배포 없이 값만 바꿀 수 있다.
`configparser`는 INI 형식을 읽는 표준 라이브러리다.

```python
import configparser

config = configparser.ConfigParser()
config.read("config.ini", encoding="utf-8")

threshold = float(config["monitor"]["threshold"])
delay_minutes = float(config["monitor"]["delay_minutes"])
```

`[monitor]`는 섹션 이름이며, 키 이름은 자유롭게 정의한다. 아래는 2편 CPU 모니터링에서 쓰는 예시다.

```ini
[monitor]
threshold = 80.0
delay_minutes = 5
lookback_seconds = 600
```

- `threshold` — 알림을 발생시킬 CPU % 상한
- `delay_minutes` — 사이클 간 대기 시간(분)
- `lookback_seconds` — 메트릭 조회 시 과거 몇 초까지 볼지

---

# 대상 목록 읽기

모니터링·자동화 대상은 DB 대신 텍스트 파일로 관리하는 경우가 많다.
탭(`\t`)으로 필드를 구분하면 엑셀에서 복사해 붙이기 쉽고, `#`으로 시작하는 줄은 주석으로 건너뛴다.

```python
def load_targets(path: str) -> list[tuple[str, str]]:
    targets = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            name, ip = line.split("\t")
            targets.append((name.strip(), ip.strip()))
    return targets
```

반환값은 `(이름, IP)` 튜플의 리스트다. 3편에서는 `(호스트, 도메인)`으로 필드 의미만 바뀐다.

입력 파일 형식 예시:

```
web-01	10.0.0.1
web-02	10.0.0.2
```

왼쪽 열은 AWS 인스턴스 이름, 오른쪽은 알림 메시지에 표시할 IP다.

---

# 주기 실행

모니터링 스크립트는 한 번 실행하고 끝나는 경우보다, 일정 간격으로 반복하는 경우가 많다.
`while True`와 `time.sleep`으로 구현하면 OS 스케줄러 없이도 상시 동작시킬 수 있다.

```python
import time

while True:
    run_once()  # 대상 순회 + 외부 호출
    time.sleep(int(delay_minutes * 60))
```

`run_once()` 안에서 대상 목록을 순회하고 외부 API를 호출한다.
대안으로 스크립트는 `run_once()`만 포함하고, 실행 주기는 cron이나 작업 스케줄러에 맡기는 방식도 흔하다. 후자는 프로세스가 매번 새로 시작되므로 메모리 누수에 유리하다.

---

# 비밀 정보

토큰·키·비밀번호를 소스에 하드코딩하면 git 히스토리에 영구 남는다.
`os.getenv()`로 환경 변수에서 읽고, 없으면 해당 채널만 비활성화하는 패턴이 안전하다.

```python
import os

token = os.getenv("TELEGRAM_BOT_TOKEN")
if token:
    send_telegram(token, os.getenv("TELEGRAM_CHAT_ID"), message)
```

`send_telegram`은 2편에서 HTTP POST 한 번으로 구현한다. 환경 변수가 설정되지 않았을 때 예외를 던지지 않고 조용히 넘어가도록 하는 것이 운영 시 편하다.

---

# 외부 연동 방식

| 방식 | 장점 | 단점 |
|------|------|------|
| `subprocess` + CLI | 의존성 적음 | 파싱·에러 처리 수동 |
| SDK (boto3, paramiko) | 예외 처리 명확 | 패키지 설치 필요 |
| HTTP (`requests`) | 범용 | 인증·재시도 직접 구현 |

2편은 AWS CLI(`subprocess`)를, 3편은 paramiko(SDK)를 택했다. 프로토타입은 CLI가 빠르고, 테스트·유지보수가 필요해지면 SDK로 옮기는 경우가 많다.

---

# 시리즈 구성

| # | 주제 | 핵심 기술 |
|---|------|-----------|
| 0 | 환경 설정 | venv, pip |
| 1 | (현재) 패턴 개요 | config, 루프, 환경 변수 |
| 2 | CPU 모니터링 | AWS CLI, 메트릭 JSON, 알림 |
| 3 | HTTPS 자동화 | SSH, certbot |
| 4 | Play 메트릭 | google-play-scraper, DB |
| 5 | LLM 배치 변환 | OpenAI API, 청크·후처리 |
| 6 | 메일 파싱 | POP3, MIME, 헤더 디코딩 |
| 7 | SERP (Selenium) | WebDriver, CSS 셀렉터 |
| 8 | SERP (HTTP) | requests, BeautifulSoup, Pool |
| 9 | TSV 입력 | 증분 INSERT, ingest 폴더 |
| 10 | Selenium 병렬 | Pool, wrapper·worker, 청크 (범용) |
| 11 | subprocess 격리 | Popen, timeout, worker 분리 |
| 12 | HTTP DB 프록시 | 서명, SELECT 페이징, upsert |
| 13 | 데스크톱 입력 | PyAutoGUI, 클립보드 붙여넣기 |

---

# 안 쓸 것

- 클라이언트·서비스 이름, 실제 운영 URL·IP
- 비공개 repo 코드
- 실제 API 토큰·SSH 키·계정 정보
- SEO·키워드 운영 실무 같은 비개발 얘기
