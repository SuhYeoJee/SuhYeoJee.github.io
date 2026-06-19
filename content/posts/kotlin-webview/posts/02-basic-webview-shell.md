---
title: Kotlin WebView — WebView 기본 셸
description: ""
date: 2026-06-17T10:00:00.000Z
preview: ""
draft: false
tags:
    - Kotlin
    - WebView
    - Android
categories:
    - Manual
series: ["Kotlin WebView 아카이브"]
---

## 개요

가장 단순한 형태: Activity 하나, WebView 하나, 홈 URL 로드.
초기 템플릿은 XML에 WebView를 박아 두거나, 코드에서 생성해 붙이는 두 방식이 있었다. 여기서는 **XML 고정 WebView**로 시작한다.

[Flutter WebView 시리즈 2편](../flutter-webview/posts/02-basic-webview.md)과 동일한 최소 기능(설정, 뒤로가기, 종료 다이얼로그)을 Kotlin으로 옮긴다.

블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## 레이아웃

```xml
<!-- res/layout/activity_main.xml -->
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/root"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <WebView
        android:id="@+id/webview"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</FrameLayout>
```

`strings.xml`에 데모 URL을 둔다.

```xml
<resources>
    <string name="app_name">WebView Shell</string>
    <string name="HOME_URL">https://example.com</string>
</resources>
```

---

## WebView 설정

JS·로컬 스토리지·뷰포트는 하이브리드 웹에서 거의 필수다.

```kotlin
@SuppressLint("SetJavaScriptEnabled")
private fun configureWebView(webView: WebView) {
    webView.settings.apply {
        javaScriptEnabled = true
        domStorageEnabled = true
        useWideViewPort = true
        loadWithOverviewMode = true
        loadsImagesAutomatically = true
        setSupportMultipleWindows(true)
        javaScriptCanOpenWindowsAutomatically = true
    }
}
```

- `domStorageEnabled` — SPA·localStorage 사용 사이트
- `setSupportMultipleWindows` — 4편 `window.open` 대비 (여기서 켜 두는 것이 일반적)

---

## Activity 전체 골격

```kotlin
class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        supportActionBar?.hide()

        webView = findViewById(R.id.webview)
        configureWebView(webView)
        webView.webViewClient = AppWebViewClient()
        webView.loadUrl(getString(R.string.HOME_URL))
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            showExitDialog()
        }
    }

    private fun showExitDialog() {
        AlertDialog.Builder(this)
            .setMessage("앱을 종료하시겠습니까?")
            .setPositiveButton("예") { _, _ -> finish() }
            .setNegativeButton("아니오", null)
            .show()
    }
}
```

`onBackPressed()`는 API 33+에서 `OnBackPressedDispatcher`로 옮기는 것이 권장되지만, 당시 템플릿은 위 패턴이었다.

---

## URL 가로채기 (전화)

웹의 `tel:` 링크는 WebView가 아니라 다이얼러로 보낸다.

```kotlin
private inner class AppWebViewClient : WebViewClient() {
  override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
        if (url.startsWith("tel:")) {
            startActivity(Intent(Intent.ACTION_DIAL, Uri.parse(url)))
            return true
        }
        return false  // 같은 WebView에서 로드
    }
}
```

`return false` — WebView가 직접 navigation 처리. `return true` — 앱이 처리 완료, WebView는 로드하지 않음.

---

## 스플래시 (선택)

일부 앱은 **SplashActivity** → **MainActivity** 순으로 넘겼다. 스플래시는 `Handler.postDelayed`로 1~2초 후 `startActivity`만 하면 된다. WebView 로직과 분리해 두면 3편 Fragment 구조로 옮기기 쉽다.

---

## 3편·5편으로 가는 이유

- XML 고정 WebView는 단순하지만, **두 번째 WebView를 FrameLayout에 swap**하려면 코드 생성 방식이 더 많이 쓰였다 (5편).
- Activity가 비대해지면 WebView 블록을 **Fragment**로 분리한다 (3편).
