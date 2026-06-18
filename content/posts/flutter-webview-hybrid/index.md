---
title: Flutter WebView 하이브리드 앱 — 패턴 정리
description: WebView 셸 패턴 정리. 듀얼 컨트롤러는 기능 보완이 아닌 셸 변형 예시다.
date: 2026-06-18T10:00:00.000Z
preview: ""
draft: false
tags:
    - Flutter
    - WebView
    - 하이브리드앱
    - webview_flutter
    - DualWebView
categories:
    - Manual
series: ["Flutter WebView 앱"]
---

# 개요

기존 웹(랜딩·서비스 페이지)을 감싸는 **하이브리드 앱**은 “웹뷰 하나 띄우기”에서 끝나지 않는다.
브라우저가 알아서 해 주던 것—뒤로가기, 외부 링크 처리, 부가 UI—을 **앱 셸**이 대신 정의해야 한다.

이 글은 시리즈 초안(`flutter-webview/`)에 흩어져 있던 테크닉을 **한 편으로 압축**한다.
구현 코드 전체가 목적이 아니라, 하이브리드 셸에서 반복해서 쓰는 **설계 단위**를 정리한다.

통합 예제: `examples/webview_shell`

---

# 하이브리드 셸이 맡는 일

| 역할 | 브라우저 | 하이브리드 앱 |
|------|----------|---------------|
| 진입점 | 주소창 | 고정 URL 또는 번들 HTML |
| 내부 이동 | 탭 히스토리 | WebView 1개(기본) 또는 2개(셸 변형) |
| 외부 링크 | 새 탭/앱 | `url_launcher` 등으로 위임 |
| 뒤로가기 | 히스토리 소진 시 탭 닫힘 | `canGoBack()` → 없으면 종료 확인 |
| 부가 기능 | 확장 프로그램 | 네이티브 화면 + FAB 등 |

셸은 **웹 콘텐츠를 바꾸지 않고** 동작 규칙만 앱 쪽에 둔다. 웹 팀·앱 팀 경계를 유지하려는 선택이다.

---

# 테크닉 1 — 링크 규칙 (Navigation Policy)

가장 먼저 정하는 것: **어떤 URL을 앱 안에 둘지**.

`NavigationDelegate.onNavigationRequest`에서 분기한다.

| 신호 | 처리 |
|------|------|
| `tel:`, `mailto:` | 무조건 외부 앱 |
| 같은 서비스(도메인·번들 HTML) | 앱 안 이동 |
| 결제·SNS·타 사이트 `https://` | 외부 브라우저/앱 |

핵심은 **명시적 화이트리스트**다. “일단 다 열기”는 나중에 결제 팝업·OAuth에서 터진다.

데모 모드에서는 `assets/demo/*.html`만 내부, 나머지 https는 외부로 보내는 식으로 같은 규칙을 연습한다.

---

# 테크닉 2 — 듀얼 WebView 컨트롤러 (셸 변형)

단일 `WebViewController`만으로도 링크 규칙·뒤로가기·종료 다이얼로그는 충분히 구현할 수 있다. (`01_basic_webview`가 그 형태다.)

**듀얼 컨트롤러**는 그런 기능적 한계를 메우기 위한 선택이 아니다. 같은 웹을 감싸더라도 **앱마다 다른 구현 형태**를 낼 수 있게 템플릿을 나눠 둔 **셸 변형**에 가깝다.

같은 웹을 감싸더라도 **패키지·네비·부가 화면 조합이 다른** 셸 변형을 만들 때 쓰는 패턴은 아래와 같다.

1. 컨트롤러 A·B를 둔다.
2. 내부 이동 시 **지금 보이지 않는 쪽**에 로드하고 `Offstage`로 표시만 바꾼다.
3. 뒤로가기는 활성·비활성 컨트롤러를 오가며 처리한다.

이 구조는 **히스토리를 완벽히 복원하는 해법**이라기보다, 가로채기와 화면 전환을 **다른 방식으로 조립**해 보여 주는 예제다. 필요 없으면 단일 컨트롤러 셸만 써도 된다.

브라우저 탭을 두 개 번갈아 쓰는 것과 비슷한 **구현 레시피**이지, 하이브리드 앱의 필수 요건은 아니다.

---

# 테크닉 3 — 뒤로가기·종료 계약

시스템 뒤로가기와 앱 UI 뒤로 버튼은 **같은 로직**을 쓴다.

1. WebView(들)에 히스토리가 있으면 `goBack()`.
2. 없으면 즉시 `SystemNavigator.pop()` 하지 말고 **종료 확인 다이얼로그**.
3. `PopScope(canPop: false)`로 OS 뒤로가기도 같은 경로로 태운다.

사용자는 “웹 한 단계 뒤”와 “앱 종료”를 구분하지 않는다. 셸이 그 경계를 지켜 줘야 한다.

---

# 테크닉 4 — 웹→네이티브 신호

웹을 수정하지 않고도, **특정 페이지에서만** 네이티브 UI(타이머·계산기·QR 등)를 켜야 할 때가 있다.

**URL 쿼리 계약** 예:

```
index.html?feature=timer  → 타이머 FAB 표시
index.html              → FAB 숨김
```

`onPageStarted`에서 URL을 파싱해 FAB·메뉴 노출 여부만 갱신한다. `onPageFinished`보다 반응이 빠르게 느껴지는 경우가 많다.

| 방식 | 장점 | 단점 |
|------|------|------|
| URL 쿼리 | 구현 단순, 웹은 링크만 추가 | 쿼리 노출, 캐시 이슈 |
| JS 채널 | 유연 | 웹·앱 양쪽 수정 |
| postMessage | 표준적 | 설정 부담 |

랜딩 래퍼 수준이면 쿼리만으로도 충분한 경우가 많다.

---

# 테크닉 5 — 네이티브 부가 화면

부가 기능은 WebView **밖** Flutter 화면으로 분리한다.

1. WebView 레이아웃은 건드리지 않는다.
2. FAB·딥링크·쿼리로 **진입점**만 연다.
3. `Navigator.push`로 `timer_page.dart` 같은 독립 파일을 연다.
4. 템플릿 복사 시 필요한 화면만 골라 넣는다.

타이머·QR·캘린더는 **플러그인처럼** 붙이고, 안 쓰는 기능은 빌드에서 빼 불필요한 권한·앱 크기 부담을 줄인다.

---

# 테크닉 6 — 하단 툴바 (선택)

브라우저 UI가 없으므로 하이브리드 셸에서 자주 넣는 네 가지:

| 버튼 | 역할 |
|------|------|
| 뒤로 | 테크닉 3과 동일 |
| 홈 | 진입 URL/에셋 재로드 |
| 맨위로 | `window.scrollTo` |
| 새로고침 | `reload()` |

듀얼 컨트롤러를 쓸 때도 **활성 컨트롤러**에만 명령을내면 된다.

---

# 통합 예제 `webview_shell`

세 개의 분리 예제를 하나로 합쳤다.

| 이전 예제 | 통합 예제에서 |
|-----------|---------------|
| `01_basic_webview` | 하단 툴바, 링크 규칙, 종료 다이얼로그 |
| `03_dual_webview` | 듀얼 컨트롤러 + `Offstage` (셸 변형) |
| `04_web_to_native_fab` | `?feature=timer` FAB + `TimerPage` |

```
webview_shell/
  lib/
    main.dart           # 셸 (듀얼 WebView + 툴바 + FAB)
    app_config.dart     # 홈 URL / 데모 모드
    web_contract.dart   # URL 파싱·링크 분류
    exit_dialog.dart
    timer_page.dart
  assets/demo/          # index, page2, page3
```

실행 (플랫폼 폴더는 로컬에서 생성):

```bash
cd examples/webview_shell
flutter create . --project-name webview_shell
flutter pub get
flutter run
```

Windows에서 경로에 한글이 있으면 Gradle 오류가 날 수 있다. ASCII 경로(`C:\dev\webview_shell` 등)를 권장한다. 세팅·트러블슈팅은 [0편](../flutter-webview/posts/00-setup-and-run.md) 참고.

---

# 데모 시나리오

1. **내부 이동** — Home → Page 2 → Page 3 (듀얼 컨트롤러 변형으로 동작 확인)
2. **외부 링크** — `flutter.dev`, `tel:` 은 외부 앱
3. **FAB** — `?feature=timer` 링크에서 타이머 FAB → 네이티브 타이머 화면
4. **툴바** — 맨위로·새로고침·홈

---

# 마치며

하이브리드 WebView 앱의 뼈대는 다음 다섯 가지다.

1. **링크 규칙** — 안/밖 경계
2. **셸 형태** — 단일 WebView(기본) 또는 듀얼 컨트롤러(변형)
3. **뒤로가기·종료** — 히스토리 소진 후 다이얼로그
4. **웹→네이티브 신호** — URL·쿼리·채널
5. **부가 화면** — WebView 밖 Flutter 페이지

패키지는 바뀌어도 이 단위는 그대로 재사용된다. 세부 구현·단계별 글은 `flutter-webview/` 시리즈 초안을, 실행 가능한 최소 샘플은 `examples/webview_shell`을 보면 된다.
