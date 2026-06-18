---
title: PyAutoGUI 데스크톱 입력 자동화
description: ""
date: 2026-06-21T11:00:00.000Z
preview: ""
draft: true
tags:
    - Python
    - PyAutoGUI
    - GUI
    - 자동화
categories:
    - Manual
series: ["Python 자동화 아카이브"]
---

# 개요

**PyAutoGUI**는 마우스·키보드를 OS 수준에서 시뮬레이션한다. API가 없는 데스크톱 프로그램, IME(한글 입력기), 수동 확인 단계를 자동화할 때 쓴다.

7~10편 Selenium·HTTP와 달리 **브라우저 DOM이 아니라 화면 좌표·키 이벤트**를 다룬다. 배치 서버보다 **로컬 PC에서 사람 대신 클릭·입력**하는 용도에 가깝다.
데모 좌표·입력만 사용하며, 실서비스 화면·계정은 넣지 않는다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

# 처리 흐름

```
스크립트 시작
    ↓
(선택) 대기 시간 — 사용자가 대상 창 포커스
    ↓
hotkey / click / type / press
    ↓
다음 단계 또는 종료
```

좌표는 해상도·창 위치에 의존하므로 테스트 환경을 고정하는 것이 중요하다.

---

# 설치와 안전장치

```bash
pip install pyautogui
```

```python
import pyautogui

pyautogui.FAILSAFE = True   # 마우스를 화면 왼쪽 위로 옮기면 예외로 중단
pyautogui.PAUSE = 0.1       # 각 동작 후 0.1초 대기
```

`FAILSAFE`는 무한 루프·잘못된 클릭 시 긴급 정지용이다.

---

# 실행 전 대기

자동화 대상 창을 활성화할 시간을 준다.

```python
import time
import pyautogui

print("3초 후 시작합니다. 대상 창을 클릭하세요.")
time.sleep(3)
pyautogui.click(500, 300)  # 데모 좌표
```

좌표는 `pyautogui.position()`으로 마우스 위치를 읽어 미리 기록한다.

---

# 키보드 입력 (ASCII)

```python
pyautogui.write("hello", interval=0.05)
pyautogui.press("enter")
pyautogui.hotkey("ctrl", "c")
```

`write()`는 영문·숫자에 적합하다. 한글은 IME 상태에 따라 동작이 달라진다.

---

# 한글 입력 — IME 전환 + 키 입력

Windows에서 한글 모드로 바꾼 뒤, **로마자 키 시퀀스**로 한글을 치는 방식(두벌식)이다.

```python
import time
import pyautogui

def type_korean_via_ime(text: str) -> None:
    pyautogui.hotkey("alt", "shift")  # IME 한/영 전환 (환경마다 다를 수 있음)
    time.sleep(0.2)
    for char in text:
        pyautogui.press(char)
        time.sleep(0.05)

# "안녕" → 로마자 "dkssud" 등 환경에 맞는 시퀀스를 넣어야 함
time.sleep(3)
type_korean_via_ime("dkssudgktpdy")
```

IME 단축키·레이아웃은 PC마다 다르다. **실무에서는 클립보드 붙여넣기가 더 안정적**인 경우가 많다.

---

# 한글 입력 — 클립보드 (권장 대안)

```python
import pyperclip
import pyautogui
import time

def paste_korean(text: str) -> None:
    pyperclip.copy(text)
    time.sleep(0.1)
    pyautogui.hotkey("ctrl", "v")

time.sleep(3)
paste_korean("데모 한글 텍스트")
```

`pip install pyperclip`. 포커스가 입력 필드에 있어야 한다.

---

# 마우스

```python
x, y = 400, 300
pyautogui.moveTo(x, y, duration=0.3)
pyautogui.click()
pyautogui.doubleClick()
pyautogui.scroll(-3)  # 아래로 스크롤
```

`locateOnScreen('button.png')`으로 이미지 매칭 클릭도 가능하나, 해상도·테마 변경에 취약하다.

---

# Selenium과 병행 (선택)

브라우저는 Selenium, **OS 대화상자·다른 앱**은 PyAutoGUI로 처리하는 하이브리드가 있다.

| 영역 | 도구 |
|------|------|
| 웹 페이지 DOM | Selenium (7편) |
| 파일 선택 창, 알림, IME | PyAutoGUI |
| 대량 HTTP | requests (8편) |

같은 스크립트에서 Selenium 세션을 연 뒤, 네이티브 창만 PyAutoGUI로 넘길 수 있다.

---

# 브라우저 창 크기 랜덤화 (관련)

자동화 탐지 완화를 위해 Chrome `--window-size`를 랜덤으로 주는 패턴도 있다. PyAutoGUI와 무관하지만 **데스크톱·브라우저 자동화** 맥락에서 같이 쓰인다.

```python
import random
from selenium.webdriver.chrome.options import Options

def chrome_options_random_size() -> Options:
    options = Options()
    w, h = random.randint(800, 1920), random.randint(600, 1080)
    options.add_argument(f"--window-size={w},{h}")
    return options
```

창 크기를 바꿀 때도 대상 사이트 **이용 약관·robots**를 먼저 확인한다. 7편 주의사항과 같다.

7편 `create_driver()`의 options에 합칠 수 있다.

---

# AutoHotkey와 비교

| | PyAutoGUI (현재) | AutoHotkey |
|--|------------------|------------|
| 언어 | Python | AHK 스크립트 |
| GUI | 코드만 | GUI 빌더·핫키 편함 |
| 배치 통합 | Python 배치와 동일 프로세스 | `python main.py` 실행 트리거 |

AHK로 GUI·핫키를 두고 Python 배치를 호출하는 조합도 흔하다. Python만 쓰려면 PyAutoGUI로 일부를 대체할 수 있다.

---

# 주의사항

- **해상도·DPI** — 좌표가 어긋남. 창 최대화·고정 레이아웃 권장
- **포커스** — 다른 창이 앞에 오면 잘못된 곳에 입력
- **headless 서버** — GUI·디스플레이 없으면 사용 불가
- **보안** — 원격 데스크톱·잠금 화면에서는 동작 제한
- **한글** — 가능하면 `pyperclip` + `ctrl+v`

---
