---
title: Python 환경 설정 (시리즈 0편)
description: ""
date: 2026-06-18T10:00:00.000Z
preview: ""
draft: true
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
2편·3편 스니펫을 돌리기 위한 최소 환경만 정리한다. 데모용 호스트·도메인만 사용한다.

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
mkdir cpu-monitor && cd cpu-monitor
python -m venv .venv
.venv\Scripts\activate
pip install requests paramiko
```

- `requests` — 2편 텔레그램 Bot API 호출에 사용
- `paramiko` — 3편 SSH 원격 명령 실행에 사용

`subprocess`, `configparser`, `json` 등은 표준 라이브러리이므로 별도 설치 없이 동작한다.

---

# 스니펫 실행 방법

각 글의 코드 블록을 하나의 파일로 합쳐 저장한 뒤 실행한다. 파일명은 자유지만 `monitor.py`처럼 역할이 드러나게 짓는 편이 관리하기 쉽다.

```bash
python monitor.py
```

2편에서 AWS CLI를 호출하는 스니펫은 Python 외에 [AWS CLI](https://aws.amazon.com/cli/)가 설치되어 있고 `aws configure`로 자격 증명이 등록되어 있어야 한다.

---

# 환경 변수

API 토큰, SSH 키 경로 같은 비밀 값은 소스 코드에 넣지 않고 셸 환경 변수로 전달한다.
Windows PowerShell·cmd에서는 `set`, Linux/macOS에서는 `export`를 사용한다.

```bash
set TELEGRAM_BOT_TOKEN=your_token
set TELEGRAM_CHAT_ID=your_chat_id
set SSH_KEY_PATH=C:\path\to\key.pem
```

코드 쪽에서는 `os.getenv()`로 읽으며, 변수가 없으면 해당 기능(알림, SSH 등)만 건너뛰도록 설계한다.

---

# 트러블슈팅

| 증상 | 확인 |
|------|------|
| `python` 명령 없음 | PATH 설정 후 터미널 재시작 |
| `ModuleNotFoundError` | venv 활성화 + `pip install` |
| AWS CLI 오류 | `aws lightsail get-instances`로 권한 확인 |
