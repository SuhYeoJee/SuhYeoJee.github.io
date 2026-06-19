---
title: Kotlin WebView — 멀티 윈도우·외부 링크
description: ""
date: 2026-06-17T11:00:00.000Z
preview: ""
draft: false
tags:
    - Kotlin
    - WebView
    - WebChromeClient
categories:
    - Manual
series: ["Kotlin WebView 아카이브"]
---

## 개요

웹 페이지가 `window.open()`으로 새 창을 열면 Android WebView는 기본적으로 무시하거나 오동작한다.
`WebChromeClient.onCreateWindow`를 구현해 **자식 WebView**를 만들거나, **외부 브라우저 Intent**로 넘겨야 한다.

초기 템플릿은 “새 WebView를 부모에 addView → 로드된 URL을 ACTION_VIEW로 넘김” 패턴이었다.

블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## 필수 WebView 설정

```kotlin
webView.settings.setSupportMultipleWindows(true)
webView.settings.javaScriptCanOpenWindowsAutomatically = true
```

둘 다 꺼져 있으면 `onCreateWindow`가 호출되지 않는다.

---

## onCreateWindow → 외부 브라우저

대표 패턴: 임시 WebView를 transport에 연결한 뒤, 그 WebView의 첫 navigation을 외부 앱으로 보낸다.

```kotlin
webView.webChromeClient = object : WebChromeClient() {
    override fun onCreateWindow(
        view: WebView,
        isDialog: Boolean,
        isUserGesture: Boolean,
        resultMsg: Message
    ): Boolean {
        val newWebView = WebView(view.context)
        val transport = resultMsg.obj as WebView.WebViewTransport
        transport.webView = newWebView
        resultMsg.sendToTarget()
        view.addView(newWebView)

        newWebView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                return true
            }
        }
        return true
    }
}
```

- `resultMsg.sendToTarget()` — Chrome이 자식 WebView와 연결되도록 **반드시** 호출
- `view.addView(newWebView)` — 부모 WebView에 자식을 붙이는 방식 (레이아웃이 단순할 때)
- 자식 WebView는 일회성이면 navigation 후 `removeView`·`destroy`로 정리하는 것이 좋다

---

## shouldOverrideUrlLoading: 스토어·전화

메인 WebViewClient에서 특수 스킴을 처리한다.

```kotlin
private fun handleIntent(url: String): Boolean {
    when {
        url.startsWith("tel:") -> {
            startActivity(Intent(Intent.ACTION_DIAL, Uri.parse(url)))
            return true
        }
        Uri.parse(url).host == "play.google.com" -> {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            intent.setPackage("com.android.vending")
            startActivity(intent)
            return true
        }
    }
    return false
}
```

`handleIntent`가 `true`를 반환하면 WebView는 해당 URL을 로드하지 않는다.

---

## 콘솔 메시지 훅 (6편 예고)

일부 템플릿은 `onConsoleMessage`에서 웹이 찍은 특정 문자열을 감지해 **전면 광고**를 띄웠다.

```kotlin
override fun onConsoleMessage(message: ConsoleMessage): Boolean {
    val log = message.message()
    if (USE_INTERSTITIALAD && log.contains(getString(R.string.ConsoleMsg))) {
        adMobManager.showInterstitialAd(this@MainActivity)
    }
    return false
}
```

웹·앱 계약은 깨지기 쉬우므로 새 프로젝트에서는 **JavascriptInterface**나 URL scheme이 더 명시적이다. 6편에서 AdMob과 함께 정리한다.

---

## Flutter와 비교

Flutter `inappwebview`는 `onCreateWindow` 콜백이 비슷한 역할을 한다.
Kotlin은 **View 계층에 WebView를 직접 추가**하는 점이 다르고, 메모리 누수 방지를 개발자가 더 신경 써야 한다.
