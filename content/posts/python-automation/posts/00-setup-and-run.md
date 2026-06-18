---
title: Python 환경 설정 (시리즈 0편)
description: ""
date: 2026-06-18T10:00:00.000Z
preview: ""
draft: false
tags:
    - Python
    - Setup
    - Windows
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

# 개요

이 시리즈는 별도 예제 프로젝트 없이, 각 글 본문의 코드 블록을 복사해 실행하는 방식이다.
시리즈 스니펫을 돌리기 위한 최소 환경을 정리한다. 데모용 호스트·도메인·계정만 사용한다.

---

# Python 설치

Windows 기준으로 3.10 이상을 설치한다. 설치 마법사에서 **"Add python.exe to PATH"**를 반드시 체크해야 터미널 어디서든 `python` 명령을 쓸 수 있다.

설치 후 새 터미널을 열고 아래 명령으로 버전을 확인한다. 두 줄 모두 버전 문자열이 출력되면 PATH와 pip가 정상이다.

```bash
python --version
pip --version
```

---

# 가상환경 (권장)

스크립트마다 패키지 버전이 달라질 수 있으므로, 작업 폴더 안에 가상환경을 만드는 것을 권장한다.
아래 명령은 작업 디렉터리 생성 → venv 생성 → 활성화 → 의존성 설치 순서다.

```bash
mkdir py-automation && cd py-automation
python -m venv .venv
.venv\Scripts\activate
pip install requests paramiko google-play-scraper openai selenium webdriver-manager beautifulsoup4 pyautogui pyperclip
```

- `requests` — 2편 텔레그램 Bot API, 8·12편 HTTP
- `paramiko` — 3편 SSH 원격 명령 실행
- `google-play-scraper` — 4편 Play 스토어 조회
- `openai` — 5편 LLM API 호출
- `selenium`, `webdriver-manager` — 7·10편 브라우저 자동화
- `beautifulsoup4` — 8편 HTML 파싱
- `pyautogui`, `pyperclip` — 13편 데스크톱 입력·클립보드 붙여넣기

`subprocess`, `configparser`, `json`, `poplib`, `email` 등은 표준 라이브러리이므로 별도 설치 없이 동작한다. 6편 POP3·MIME 파싱, 9편 TSV 읽기에 쓴다.

---

# 스니펫 실행 방법

각 글의 코드 블록을 하나의 파일로 합쳐 저장한 뒤 실행한다. 파일명은 자유지만 `monitor.py`처럼 역할이 드러나게 짓는 편이 관리하기 쉽다.

```bash
python monitor.py
```

2편에서 AWS CLI를 호출하는 스니펫은 Python 외에 [AWS CLI](https://aws.amazon.com/cli/)가 설치되어 있고 `aws configure`로 자격 증명이 등록되어 있어야 한다.
7·10편은 Chrome 브라우저가 로컬에 있어야 한다. 13편은 GUI가 있는 로컬 PC가 필요하다. 2~13편은 해당 편에서 안내하는 패키지·환경 변수만 추가로 준비하면 된다.

---

# 환경 변수

API 토큰, SSH 키 경로 같은 비밀 값은 소스 코드에 넣지 않고 셸 환경 변수로 전달한다.
Windows PowerShell·cmd에서는 `set`, Linux/macOS에서는 `export`를 사용한다.

```bash
set TELEGRAM_BOT_TOKEN=your_token
set TELEGRAM_CHAT_ID=your_chat_id
set SSH_KEY_PATH=C:\path\to\key.pem
set OPENAI_API_KEY=your_key
set MAIL_USER=user@example.com
set MAIL_PASSWORD=your_password
set API_SALT=your_api_salt
```

- `OPENAI_API_KEY` — 5편 LLM 호출
- `MAIL_USER`, `MAIL_PASSWORD` — 6편 POP3 데모 접속 (선택)
- `API_SALT` — 12편 HTTP DB API 요청 서명

코드 쪽에서는 `os.getenv()`로 읽으며, 변수가 없으면 해당 기능(알림, SSH 등)만 건너뛰도록 설계한다.

---

# 트러블슈팅

| 증상 | 확인 |
|------|------|
| `python` 명령 없음 | PATH 설정 후 터미널 재시작 |
| `ModuleNotFoundError` | venv 활성화 + `pip install` |
| AWS CLI 오류 | `aws lightsail get-instances`로 권한 확인 |
| Selenium 오류 | Chrome 설치, `webdriver-manager` 버전 확인 |
