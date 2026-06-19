---
title: Kotlin WebView — 듀얼 WebView (도메인 분기)
description: ""
date: 2026-06-17T11:30:00.000Z
preview: ""
draft: false
tags:
    - Kotlin
    - WebView
    - Navigation
categories:
    - Manual
series: ["Kotlin WebView 아카이브"]
---

## 개요

메인 사이트(`example.com`) 안에서는 WebView 하나로 충분하지만, **결제·제휴·외부 콘텐츠**는 다른 도메인으로 나간다.
듀얼 WebView 패턴은 **webView1 = 홈 스택**, **webView2 = 외부 도메인 스택**으로 나누고, `FrameLayout`에서 보이는 쪽만 교체한다.

[Flutter WebView 시리즈 3편](../flutter-webview/posts/03-dual-webview.md)(듀얼 WebView)과 같은 설계이다.

블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## strings.xml

```xml
<resources>
    <string name="HOME_URL">https://example.com</string>
    <string name="HOME_DOMAIN">example.com</string>
</resources>
```

도메인 비교는 `contains`로 느슨하게 했던 템플릿도 있었다. 서브도메인 정책에 맞게 `host` equality로 바꾸는 편이 안전하다.

---

## 두 WebView 준비

```kotlin
class MainActivity : AppCompatActivity() {
    private lateinit var webView1: WebView
    private var webView2: WebView? = null
    private var isWebView1Visible = true
    private lateinit var frameLayout: FrameLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        frameLayout = findViewById(R.id.WebView_frame)

        webView1 = WebView(this).also { w ->
            webViewSetting(w)
            w.webViewClient = PrimaryClient()
            w.webChromeClient = SharedChromeClient()
            w.loadUrl(getString(R.string.HOME_URL))
        }
        frameLayout.addView(webView1)
    }
}
```

`webView2`는 처음부터 만들지 않고, **외부 도메인 링크가 처음 나올 때** lazy 생성했다.

---

## Primary WebViewClient: 도메인 분기

```kotlin
private inner class PrimaryClient : WebViewClient() {
    override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
        if (url == null) return false
        if (handleIntent(url)) return true

        val host = Uri.parse(url).host ?: return false
        val homeDomain = getString(R.string.HOME_DOMAIN)

        return if (!host.contains(homeDomain)) {
            if (webView2 == null) {
                webView2 = WebView(this@MainActivity).also { w ->
                    webViewSetting(w)
                    w.webViewClient = SecondaryClient()
                    w.webChromeClient = SharedChromeClient()
                }
            }
            webView2!!.loadUrl(url)
            showWebView2()
            true
        } else {
            false  // webView1에서 계속
        }
    }
}
```

- 외부 도메인 → `webView2.loadUrl` + `showWebView2()`
- 홈 도메인 → `false`로 WebView1 내비게이션 유지

---

## Secondary WebViewClient

외부 스택에서는 **Intent 처리만** 하고 나머지는 WebView2 안에서 history를 쌓는다.

```kotlin
private inner class SecondaryClient : WebViewClient() {
    override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
        if (url == null) return false
        return handleIntent(url)
    }
}
```

---

## FrameLayout swap

```kotlin
private fun showWebView1() {
    webView2?.let { frameLayout.removeView(it) }
    frameLayout.removeView(webView1)
    frameLayout.addView(webView1)
    isWebView1Visible = true
}

private fun showWebView2() {
    frameLayout.removeView(webView1)
    webView2?.let { frameLayout.addView(it) }
    isWebView1Visible = false
}
```

한 번에 **하나의 WebView만** 프레임에 올린다. 두 WebView를 동시에 `VISIBLE`로 두지 않는다.

---

## 뒤로가기

```kotlin
override fun onBackPressed() {
    val current = if (isWebView1Visible) webView1 else webView2
    if (current?.canGoBack() == true) {
        current.goBack()
    } else if (isWebView1Visible) {
        showExitDialog()
    } else {
        showWebView1()
        webView2?.destroy()
        webView2 = null
    }
}
```

외부 스택 루트에서 뒤로가면 **webView1으로 복귀**하고 webView2를 destroy해 메모리를 돌려준다.

---

## 공유 버튼

```kotlin
private fun handleShareButton() {
    val url = if (isWebView1Visible) webView1.url else webView2?.url
    val sendIntent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, url)
    }
    startActivity(Intent.createChooser(sendIntent, "공유하기"))
}
```

현재 보이는 스택의 URL을 공유한다. `bool.xml`의 `USE_SHAREBTN`으로 표시 여부를 토글했다 (8편).

---

## 주의점

- `removeView`만 하고 `destroy`하지 않으면 WebView 프로세스가 남을 수 있다.
- 외부 도메인 판별을 `contains`만 쓰면 `notexample.com` 같은 호스트에 오판할 수 있다.
- 멀티 윈도우(4편)와 듀얼 WebView를 동시에 켜면 동작이 복잡해져, 듀얼 WebView 템플릿에서는 `setSupportMultipleWindows`를 끈 경우도 있었다.
