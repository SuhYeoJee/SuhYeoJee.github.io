---
title: Kotlin WebView — Fragment에 WebView 호스팅
description: ""
date: 2026-06-17T10:30:00.000Z
preview: ""
draft: false
tags:
    - Kotlin
    - WebView
    - Fragment
categories:
    - Manual
series: ["Kotlin WebView 아카이브"]
---

## 개요

Activity에 WebView 로직을 모두 넣으면 파일이 금방 비대해진다.
**MainActivity는 컨테이너**, **MainFragment가 WebView를 소유**하는 구조로 나누면 탭·스플래시·다른 화면을 붙이기 쉽다.

블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## Activity: Fragment 호스트

```kotlin
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        supportActionBar?.hide()

        if (savedInstanceState == null) {
            supportFragmentManager.beginTransaction()
                .replace(R.id.fragment_container, MainFragment())
                .commit()
        }
    }
}
```

```xml
<!-- activity_main.xml -->
<FrameLayout
    android:id="@+id/fragment_container"
    android:layout_width="match_parent"
    android:layout_height="match_parent" />
```

`savedInstanceState == null`일 때만 Fragment를 붙여 회전 시 중복 추가를 막는다.

---

## Fragment 레이아웃

```xml
<!-- fragment_main.xml -->
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <WebView
        android:id="@+id/FragWeb"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</FrameLayout>
```

---

## MainFragment

```kotlin
class MainFragment : Fragment() {

    private lateinit var webView: WebView

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val view = inflater.inflate(R.layout.fragment_main, container, false)
        webView = view.findViewById(R.id.FragWeb)

        val url = getString(R.string.HOME_URL)
        webView.apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.useWideViewPort = true
            settings.loadsImagesAutomatically = true
            settings.setSupportMultipleWindows(true)
            settings.loadWithOverviewMode = true
            setInitialScale(1)
        }

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
                if (url.startsWith("tel:")) {
                    startActivity(Intent(Intent.ACTION_DIAL, Uri.parse(url)))
                    return true
                }
                return false
            }
        }

        webView.loadUrl(url)
        return view
    }
}
```

Fragment에서는 `startActivity`가 그대로 동작한다. `requireContext()`가 필요한 API는 lifecycle 안에서 호출한다.

---

## 뒤로가기

Fragment 단독으로는 시스템 뒤로가기를 받기 어렵다. 패턴 두 가지:

**A. Activity에서 WebView 참조**

```kotlin
// MainActivity
override fun onBackPressed() {
    val frag = supportFragmentManager.findFragmentById(R.id.fragment_container)
    if (frag is MainFragment && frag.handleBack()) return
    super.onBackPressed()
}

// MainFragment
fun handleBack(): Boolean {
    return if (webView.canGoBack()) {
        webView.goBack()
        true
    } else false
}
```

**B. OnBackPressedCallback** (권장, API  androidx)

Fragment의 `onViewCreated`에서 `requireActivity().onBackPressedDispatcher.addCallback`로 등록한다.

---

## 4편과의 연결

실제 Fragment 템플릿에는 **WebChromeClient.onCreateWindow**가 같이 들어 있었다.
`window.open`으로 열린 보조 WebView를 Fragment 뷰 트리에 붙이거나, 최종 URL을 외부 브라우저로 넘기는 처리는 4편에서 다룬다.
