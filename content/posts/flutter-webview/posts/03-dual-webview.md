---
title: Flutter 듀얼 WebView — 컨트롤러 두 개로 히스토리 살리기
description: ""
date: 2026-06-16T14:00:00.000Z
preview: ""
draft: true
tags:
    - Flutter
    - webview_flutter
    - DualWebView
categories:
    - Manual
series: ["Flutter WebView 앱"]
---

# 개요

2편은 WebView 하나로 충분했다.
3세대 템플릿에서 제일 헷갈렸던 건 **컨트롤러를 두 개 두고 `Offstage`로 갈아끼우는 패턴**이다.

예제: `examples/03_dual_webview`

---

# 왜 컨트롤러가 두 개인가

같은 도메인 안에서 페이지를 여러 번 열면 WebView 히스토리가 쌓인다.
그런데 링크 가로채기를 쓰면 `prevent` 하고 직접 `loadRequest` 하는 경우가 많다.
그러면 **뒤로가기 스택이 기대랑 다르게** 느껴진다.

해결책으로 쓴 방법:

1. 컨트롤러 A, B를 둔다
2. 새 페이지는 **지금 안 보이는 쪽**에 로드한다
3. `Offstage`로 보이는 쪽만 바꾼다
4. 뒤로가기는 **현재 → 이전 컨트롤러** 순으로 `canGoBack()` 확인

브라우저 탭 두 개를 번갈아 쓰는 느낌에 가깝다.

---

# 화면 구조

```dart
Stack(
  children: [
    Offstage(
      offstage: !_showPrimary,
      child: WebViewWidget(controller: _primary),
    ),
    Offstage(
      offstage: _showPrimary,
      child: WebViewWidget(controller: _secondary),
    ),
  ],
)
```

둘 다 위젯 트리에 남아 있어서 컨트롤러 상태가 유지된다.

---

# 페이지 전환

내부 링크를 누르면 기본 네비게이션 대신 비활성 컨트롤러에 로드한다.

```dart
void _switchWebView(String? assetPath) {
  setState(() => _showPrimary = !_showPrimary);
  if (assetPath != null) {
    _active.loadFlutterAsset(assetPath);
  }
}

NavigationDecision _onNavigationRequest(NavigationRequest request) {
  final asset = assetPathFromUrl(request.url);
  if (asset != null) {
    _switchWebView(asset);
    return NavigationDecision.prevent;
  }
  // tel:, 외부 https는 2편과 동일하게 밖으로
}
```

데모는 `assets/demo/*.html`을 쓴다. 실URL 모드에서는 `loadRequest(Uri.parse(url))`로 바꾸면 된다.

---

# 뒤로가기

```dart
Future<void> _handleBack() async {
  if (await _active.canGoBack()) {
    await _active.goBack();
    _switchWebView(null); // 컨트롤러만 교체, 새 URL 로드 없음
    return;
  }
  if (await _inactive.canGoBack()) {
    _switchWebView(null);
    return;
  }
  // 종료 다이얼로그
}
```

포인트는 `_switchWebView(null)` — **보이는 컨트롤러만 바꾸고** 새 페이지는 안 연다는 것.

---

# 데모 시나리오

1. Home → Page 2 → Page 3 순으로 이동
2. 뒤로가기 연타: Page 3 → 2 → Home
3. 외부 링크는 여전히 `url_launcher`

---

# 2편과 비교

| | basic_webview | dual_webview |
|--|---------------|--------------|
| 컨트롤러 | 1개 | 2개 |
| 툴바 | 있음 | AppBar 홈만 (단순화) |
| 내부 이동 | WebView 기본 네비게이션 | 가로채기 + 컨트롤러 교체 |
| 난이도 | 입문 | 중간 |

---

# 실행

```bash
cd examples/03_dual_webview
flutter create . --project-name dual_webview
flutter pub get
flutter run
```
