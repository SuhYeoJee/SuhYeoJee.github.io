---
title: Flutter WebView — 네이티브 부가 기능 붙이기
description: ""
date: 2026-06-16T19:00:00.000Z
preview: ""
draft: false
tags:
    - Flutter
    - NativeAddon
categories:
    - Manual
series: ["Flutter WebView 앱"]
---

## 개요

WebView 셸이 잡히면 그 위에 **네이티브 부가 기능**을 얹는다.
타이머, 계산기, 캘린더, QR, 스크린샷… 버전마다 하나씩 붙던 것들이다.

4편 `04_web_to_native_fab`에 타이머 예제가 있다. 이번 편은 **붙이는 방식**만 정리한다.

---

## 공통 패턴

1. WebView는 건드리지 않는다
2. `feature=xxx` 쿼리 or FAB 메뉴로 진입점을 만든다
3. `Navigator.push`로 **별도 Flutter 화면**을 연다
4. 화면은 `lib/` 아래 독립 파일 (`timer_page.dart` 등)

```
lib/
  main.dart           # WebView 셸
  timer_page.dart     # 부가 기능 A
  calculator_page.dart
  qr_scanner_page.dart
```

템플릿 복사할 때 **필요한 파일만 골라** 넣으면 된다.

---

## 타이머 (4편 예제)

- FAB → `TimerPage`
- 60초 카운트다운, 시작/일시정지/리셋
- 패키지 없이 `Timer.periodic`만 사용

변형 예로는 스톱워치·랩 기록·진동 알림 등으로 바꿀 수 있다.
진동은 `vibration` 패키지 한 줄이면 된다.

---

## 계산기 (변형 예시)

| 항목 | 내용 |
|------|------|
| 패키지 | `math_expressions` 등 |
| 진입 | `?feature=calculator` |
| UI | Grid 버튼 + 수식 Text |

WebView와 무관한 UI라서 **웹 배포 없이** 앱만 업데이트 가능.

---

## 캘린더 (변형 예시)

| 항목 | 내용 |
|------|------|
| 패키지 | `table_calendar` |
| 진입 | FAB 서브메뉴 or 쿼리 |
| 용도 | 이벤트 안내, 상담 예약 랜딩 연계 |

---

## QR / 스크린샷 (2세대에서 자주 썼음)

| 기능 | 패키지 예 | 주의 |
|------|----------|------|
| QR 스캔 | `mobile_scanner` 등 | 카메라 권한 |
| WebView 캡처 | `RepaintBoundary` + 갤러리 저장 | 저장소 권한 |

inappwebview 시절에는 서브 브라우저·모달과 섞어 썼다.
지금은 **별도 화면**으로 빼는 편이 단순하다.

---

## 기능 플래그 설계

쿼리 하나에 하나씩:

```
?feature=timer
?feature=calculator
?feature=calendar
```

여러 개 동시에 켜야 하면:

```
?features=timer,calculator
```

파싱만 `split(',')` 추가하면 된다.

---

## 배포 관점

- 부가 기능마다 **권한**이 늘어난다 (카메라, 저장소…)
- 안 쓰는 기능 파일은 빌드에서 빼 **권한·앱 크기** 부담을 줄인다
- 앱마다 **기능 조합을 다르게** 두면 유지보수와 권한 관리가 수월하다

---

## 마치며

WebView 앱은 “웹 띄우기”에서 끝이 아니다.
**셸 + 링크 규칙 + 옵션 네이티브 화면**이 합쳐져야 실무에서 쓸 만한 템플릿이 된다.

예제는 전부 `examples/` 아래에 있으며, 비공개 프로젝트 소스는 포함하지 않았다.
필요한 기능만 골라서 자기 프로젝트에 맞게 조합하면 된다.
