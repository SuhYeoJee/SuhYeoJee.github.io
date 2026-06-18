---
title: Flutter WebView — inappwebview에서 webview_flutter로
description: ""
date: 2026-06-16T18:00:00.000Z
preview: ""
draft: true
tags:
    - Flutter
    - flutter_inappwebview
    - webview_flutter
categories:
    - Manual
series: ["Flutter WebView 앱"]
---

## 개요

2세대 템플릿은 `flutter_inappwebview`였고, 3세대는 다시 `webview_flutter`로 돌아왔다.
이 편은 **별도 예제 없이** 마이그레이션 때 기억할 매핑만 정리한다.

---

## 왜 갈아탔나 (당시 기준)

- `webview_flutter` 4.x API 정리됨 (`WebViewController` 단일 객체)
- 팀이 이미 1세대·3세대에 익숙
- inappwebview는 기능은 많지만 **업데이트·빌드 이슈**가 잦았음
- 필요한 가로채기는 `NavigationDelegate`로 대부분 커버됨

정답이 아니라 **그때 요구사항에 맞는 선택**이었다.

---

## API 매핑表

| inappwebview | webview_flutter 4.x |
|--------------|---------------------|
| `InAppWebView` | `WebViewWidget(controller: ...)` |
| `initialUrlRequest` | `controller.loadRequest(uri)` |
| `shouldOverrideUrlLoading` | `NavigationDelegate.onNavigationRequest` |
| `onLoadStart` | `onPageStarted` |
| `onLoadStop` | `onPageFinished` |
| `InAppBrowser.openWithSystemBrowser` | `url_launcher` `launchUrl` |
| `onCreateWindow` (팝업) | 별도 WebView 화면 or 외부 브라우저 |
| `javaScriptEnabled` | `setJavaScriptMode(JavaScriptMode.unrestricted)` |

---

## 가로채기 예시 비교

**inappwebview (2세대 스타일)**

```dart
shouldOverrideUrlLoading: (controller, request) async {
  final url = request.url.toString();
  if (!url.contains(homeHost)) {
    await launchUrl(Uri.parse(url));
    return NavigationActionPolicy.CANCEL;
  }
  return NavigationActionPolicy.ALLOW;
},
```

**webview_flutter (이 시리즈 예제 스타일)**

```dart
onNavigationRequest: (request) {
  if (host != homeHost) {
    launchUrl(Uri.parse(request.url));
    return NavigationDecision.prevent;
  }
  return NavigationDecision.navigate;
},
```

`CANCEL` / `prevent`, `ALLOW` / `navigate` — 이름만 다르고 역할은 같다.

---

## 서브 WebView / 팝업 창

inappwebview는 `onCreateWindow`로 팝업을 받을 수 있다.
webview_flutter만 쓰면 선택지가 줄어든다.

| 상황 | 대안 |
|------|------|
| 결제·SNS 등 외부 | `url_launcher`로 시스템 브라우저 |
| 같은 서비스 내 다른 URL | 단일 WebView 또는 듀얼 WebView (3편, 셸 변형) |
| 진짜 팝업 필수 | inappwebview 유지 or 별도 Route |

---

## WillPopScope → PopScope

구버전 코드에 `WillPopScope`가 많다. 새 프로젝트는 `PopScope` 권장.

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    await _handleBack();
  },
  child: ...,
)
```

---

## 체크리스트 (마이그레이션 때)

- [ ] `WebViewController` 생성 시점 vs `loadRequest` 시점 분리
- [ ] `NavigationDelegate`에서 tel / 외부 도메인 분기
- [ ] 뒤로가기: `canGoBack()` + 종료 다이얼로그
- [ ] Android `minSdk`, iOS `Info.plist` (외부 URL, http 허용 여부)
- [ ] 팝업 창 요구사항 — 포기할지, 서브 WebView로 대체할지
- [ ] JS 브릿지 쓰던 페이지 — `addJavaScriptChannel`로 재구현

---

## 언제 inappwebview를 아직 쓸까

- `onCreateWindow` / 멀티 윈도우가 필수
- WebView 안에서 파일 업로드·인증서 등 **고급 브라우저 기능** 필요
- 이미 inappwebview에 깊게 묶인 레거시

그 외 랜딩 래퍼 수준이면 `webview_flutter` + `url_launcher` + **단일 컨트롤러 셸**로 충분한 경우가 많다. 듀얼 컨트롤러는 **다른 형태**의 템플릿이 필요할 때 고른다.
