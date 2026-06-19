---
title: Kotlin WebView — 셸 개요
description: ""
date: 2026-06-17T09:30:00.000Z
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

Android **WebView 하이브리드 셸**은 네이티브 UI를 직접 짜지 않고, 고정 **HOME URL**을 로드하는 앱 골격이다.
Fragment 분리, 듀얼 WebView, 광고·FCM 등 기능이 **템플릿 단위**로 쌓이는 패턴이 흔하다.

이 글은 그 진화를 **기술 아카이브** 관점에서 정리한다.
블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

> **면책** — 학습·설계 패턴 공유 목적이다. 예제는 데모 URL·Google 테스트 AdMob ID만 사용한다. **본인이 관리·배포 권한이 있는 앱**에만 적용하고, Play 정책·AdMob·Firebase 약관을 준수한다.

---

## 무엇을 하는 앱인가

1. 앱 실행 → 고정 **HOME URL** 로드
2. 같은 사이트 안에서는 WebView 히스토리로 이동
3. `tel:`, 스토어 링크 등은 **Intent**로 외부 앱에 위임
4. 뒤로가기: `canGoBack()`이면 `goBack()`, 아니면 종료 확인 다이얼로그
5. (선택) 공유 버튼, 광고, FCM, 듀얼 WebView

[Flutter WebView 시리즈](../flutter-webview/README.md) 1편과 목표는 같다. 구현만 Android `WebView` API에 맞춘다.

---

## 템플릿 진화 (개념)

| 단계 | 특징 | 이 시리즈 편 |
|------|------|-------------|
| 최소 셸 | XML에 WebView, JS·DOM 활성화, 뒤로가기 | 2편 |
| Fragment 호스팅 | Activity는 컨테이너, WebView는 Fragment | 3편 |
| 멀티 윈도우 | `window.open` → 새 WebView 또는 외부 브라우저 | 4편 |
| 듀얼 WebView | HOME 도메인 밖 링크는 두 번째 WebView 스택 | 5편 |
| 수익·푸시 | AdMob 전면·오픈 광고, FCM 알림 | 6~7편 |
| 운영 플래그 | `bool.xml`로 기능 on/off, cleartext 차단 | 8편 |

“버전 번호” 대신 **기능 단위**로 나눴다. 내부 프로젝트 폴더명은 글에 쓰지 않는다.

---

## 공통 파일 구조

```
app/src/main/
├── AndroidManifest.xml      # 권한, Activity, FCM Service
├── java/.../MainActivity.kt # WebView 호스트 (또는 Fragment)
├── res/
│   ├── layout/activity_main.xml
│   ├── values/strings.xml   # HOME_URL, HOME_DOMAIN (데모 값)
│   ├── values/bool.xml      # USE_SHAREBTN, USE_OPENAD 등
│   └── xml/network_security_config.xml
```

- **strings.xml** — URL·도메인·광고 단위 ID를 코드 밖으로 빼 재사용
- **bool.xml** — 빌드 variant 없이 기능 토글 (8편)
- **network_security_config** — HTTP 차단 등 네트워크 정책

---

## MainActivity의 역할

대표 템플릿에서는 Activity가 다음을 한곳에서 처리한다.

```kotlin
class MainActivity : AppCompatActivity() {
    private lateinit var webView1: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        supportActionBar?.hide()

        webView1 = WebView(this)
        webViewSetting(webView1)
        webView1.webViewClient = CustomWebViewClient()
        webView1.webChromeClient = CustomWebChromeClient()
        webView1.loadUrl(getString(R.string.HOME_URL))

        findViewById<FrameLayout>(R.id.WebView_frame).addView(webView1)
    }
}
```

- WebView를 **레이아웃 XML이 아니라 코드로 생성**해 `FrameLayout`에 붙이는 패턴이 많았다. 5편에서 두 번째 WebView를 같은 프레임에 교체할 때 유리하다.
- `webViewClient` — URL 가로채기, 페이지 로드
- `webChromeClient` — JS alert, 멀티 윈도우, 콘솔 로그

---

## 안 쓸 것 (시리즈 원칙)

- 실서비스 URL, AdMob·Firebase 실 ID
- 내부 프로젝트 코드명·폴더명
- 실제 스토어 패키지명·스크린샷

스니펫의 URL은 `https://example.com`, 도메인은 `example.com`처럼 placeholder만 사용한다.

---

## 시리즈 읽는 순서

| # | 제목 |
|---|------|
| 0 | Android Studio·Gradle 실행 |
| 1 | (이 글) 개요 |
| 2 | WebView 기본 셸 |
| 3 | Fragment에 WebView 호스팅 |
| 4 | 멀티 윈도우·외부 링크 |
| 5 | 듀얼 WebView (도메인 분기) |
| 6 | AdMob 패턴 |
| 7 | FCM 푸시 |
| 8 | 보안·설정 |

[Flutter WebView 시리즈](../flutter-webview/README.md)와 병행하면 **듀얼 WebView**(Flutter 3편 ↔ Kotlin 5편), **네이티브 FAB·부가기능**(Flutter 4~6편)을 비교할 수 있다.
