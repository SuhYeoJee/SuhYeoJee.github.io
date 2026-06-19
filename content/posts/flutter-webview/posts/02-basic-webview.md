---
title: Flutter WebView — 툴바와 뒤로가기
description: ""
date: 2026-06-16T12:00:00.000Z
preview: ""
draft: false
tags:
    - Flutter
    - webview_flutter
    - url_launcher
categories:
    - Manual
series: ["Flutter WebView 앱"]
---

## 개요

1편에서 말한 1세대 템플릿을 직접 만들어 본다.
웹페이지 하나 띄우고, 하단에 툴바 달고, 뒤로가기 누르면 종료 확인하는 것까지.

예제 코드: `examples/01_basic_webview`

비공개 프로젝트 코드는 그대로 올리지 않는다. 패턴만 가져와서 새로 짰다.

---

## 이 예제가 하는 일

1. 앱 실행 → WebView에 홈 페이지 연다 (기본은 번들 HTML)
2. 같은 데모 안의 `.html` 링크는 앱 안에서 이동
3. `https://` 다른 사이트, `tel:` 은 외부 앱으로 연다
4. 하단 툴바: 뒤로 | 홈 | 맨위로 | 새로고침
5. 히스토리 없을 때 뒤로가기 → 종료 다이얼로그

---

## 프로젝트 구조

```
01_basic_webview/
  lib/
    main.dart          # WebView + 툴바 + 뒤로가기
    app_config.dart    # URL / 데모 모드 설정
    exit_dialog.dart   # 종료 확인
  assets/demo/
    index.html         # 데모 홈
    page2.html         # 앱 내 이동 테스트
```

`flutter create`로 android/ios 폴더는 로컬에서 생성한다. README 참고.

---

## WebViewController 세팅

`webview_flutter` 4.x는 `WebViewController`를 만들고 `WebViewWidget`에 넘기는 방식이다.

```dart
_controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setNavigationDelegate(
    NavigationDelegate(onNavigationRequest: _onNavigationRequest),
  );

if (AppConfig.useBundledDemo) {
  _controller.loadFlutterAsset(AppConfig.demoAsset);
} else {
  _controller.loadRequest(Uri.parse(AppConfig.homeUrl));
}
```

데모는 `assets/demo/index.html`을 쓴다. 실서비스 URL을 넣고 싶으면 `app_config.dart`에서 `useBundledDemo = false`로 바꾸면 된다.

---

## 링크 가로채기

브라우저랑 다르게 앱은 **어디까지 앱 안에 둘지** 정해줘야 한다.

```dart
NavigationDecision _onNavigationRequest(NavigationRequest request) {
  final url = request.url;

  if (url.startsWith('tel:') || url.startsWith('mailto:')) {
    _openExternally(url);
    return NavigationDecision.prevent;
  }

  if (AppConfig.useBundledDemo) {
    if (_isBundledAssetNavigation(url)) {
      return NavigationDecision.navigate;
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      _openExternally(url);
      return NavigationDecision.prevent;
    }
  } else {
    final host = Uri.parse(url).host;
    if (host.isNotEmpty && host != homeHost) {
      _openExternally(url);
      return NavigationDecision.prevent;
    }
  }

  return NavigationDecision.navigate;
}
```

정리하면:

- `tel:` / `mailto:` → 무조건 밖으로
- 데모 모드 → `appassets` / `.html` 은 앱 안, 나머지 https는 밖으로
- 실URL 모드 → 홈과 **같은 호스트**만 앱 안

---

## 뒤로가기

시스템 뒤로가기와 툴바 뒤로 버튼이 같은 로직을 쓴다.

```dart
Future<bool> _handleBack() async {
  if (await _controller.canGoBack()) {
    await _controller.goBack();
    return false;
  }

  final shouldExit = await showExitDialog(context);
  if (shouldExit == true) {
    exitApp();
  }
  return false;
}
```

`PopScope(canPop: false)`로 감싸서, WebView에 히스토리가 없을 때 앱이 바로 꺼지지 않게 했다.

---

## 하단 툴바

| 버튼 | 동작 |
|------|------|
| 뒤로 | `_handleBack()` |
| 홈 | `loadFlutterAsset` 또는 `loadRequest(home)` |
| 맨위로 | `runJavaScript('window.scrollTo(...)')` |
| 새로고침 | `reload()` |

웹만 보여 주는 앱이라도 이 네 개는 하이브리드 셸에서 자주 넣는다. 브라우저 UI가 없으니까.

---

## 데모 HTML

`index.html`에 테스트 링크를 넣어뒀다.

- `page2.html` — 앱 안 이동 + WebView 히스토리
- `https://flutter.dev` — 외부 브라우저
- `tel:+821012345678` — 전화 앱
- 긴 여백 — 맨위로 버튼 확인용

---

## 실행

```bash
cd examples/01_basic_webview
flutter create . --project-name basic_webview
flutter pub get
flutter run
```

---

## 1편이랑 비교

| | 1편 (개념) | 이번 예제 |
|--|-----------|----------|
| WebView 패키지 | webview_flutter | 동일 |
| 툴바 | 있다 | 구현함 |
| 외부 링크 | url_launcher | 동일 |
| 듀얼 WebView | 없음 | 없음 (3편 예정) |
| FAB / QR | 2세대 | 없음 |

여기까지가 1세대 셸의 최소 단위다. 다음은 **다른 형태**의 듀얼 WebView 셸 변형(3편).
