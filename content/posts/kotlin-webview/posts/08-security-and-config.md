---
title: Kotlin WebView — 보안·설정
description: ""
date: 2026-06-17T13:00:00.000Z
preview: ""
draft: false
tags:
    - Kotlin
    - Android
    - Security
categories:
    - Manual
series: ["Kotlin WebView 아카이브"]
---

## 개요

WebView 셸을 여러 앱에 복제할 때 **URL·기능 플래그·네트워크 정책**을 리소스 파일로 빼 두면 코드 수정 없이 variant를 맞출 수 있다.
이 편은 `strings.xml`, `bool.xml`, `network_security_config`, WebView 보안 설정을 정리한다.

블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## strings.xml: 환경 분리

```xml
<resources>
    <string name="HOME_URL">https://example.com</string>
    <string name="HOME_DOMAIN">example.com</string>
    <string name="ConsoleMsg">SHOW_INTERSTITIAL</string>
    <string name="INTERSTITIALAD_CODE">ca-app-pub-3940256099942544/1033173712</string>
    <string name="OPENAD_CODE">ca-app-pub-3940256099942544/9257395921</string>
</resources>
```

빌드 flavor별 `src/staging/res/values/strings.xml`을 두면 스테이징 URL을 분리할 수 있다. 비밀 API 키는 strings에 넣지 말고 서버·원격 설정을 쓴다.

---

## bool.xml: 기능 토글

```xml
<resources>
    <bool name="USE_SHAREBTN">true</bool>
    <bool name="USE_INTERSTITIALAD">false</bool>
    <bool name="USE_OPENAD">false</bool>
</resources>
```

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    val useShare = resources.getBoolean(R.bool.USE_SHAREBTN)
  findViewById<ImageButton>(R.id.ShareButton).visibility =
        if (useShare) View.VISIBLE else View.GONE
}
```

광고·공유를 앱마다 다르게 켜고 끄는 데 사용했다. Remote Config로 옮기면 스토어 재배포 없이 바꿀 수 있다.

---

## Cleartext HTTP 차단

Android 9+는 기본적으로 **평문 HTTP**가 막힌다. 템플릿은 cleartext를 허용하지 않는 설정을 썼다.

`res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

`AndroidManifest.xml`의 `<application>`:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    android:usesCleartextTraffic="false"
    ...>
```

로컬 개발만 HTTP가 필요하면 **debug manifest**에만 예외를 두고, release에는 넣지 않는다.

---

## Mixed Content (레거시)

아주 오래된 템플릿에는 HTTPS 페이지에서 HTTP 리소스를 허용하는 설정이 있었다.

```kotlin
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
    webView.settings.mixedContentMode =
        WebSettings.MIXED_CONTENT_NEVER_ALLOW
}
```

신규 프로젝트는 웹을 전부 HTTPS로 맞추고 `NEVER_ALLOW`를 권장한다.

---

## WebView 보안 체크리스트

| 항목 | 권장 |
|------|------|
| `javaScriptEnabled` | 신뢰 URL만 로드; 파일 URL·임의 도메인 주의 |
| `addJavascriptInterface` | `@JavascriptInterface`만 노출; SDK 17 미만 타겟 금지 |
| `setAllowFileAccess` | 필요 없으면 false |
| `WebView` 디버깅 | debug 빌드만 `WebView.setWebContentsDebuggingEnabled(true)` |
| 사용자 입력 URL | `loadUrl`에 검증 없이 넣지 않음 |

---

## ProGuard / R8

Release 빌드에서 Firebase·AdMob 클래스가 난독화되지 않도록 consumer rules를 패키지 문서대로 유지한다. WebView bridge 클래스는 keep 규칙이 필요할 수 있다.

---

## 시리즈 마무리

| 편 | 주제 |
|----|------|
| 0 | Android Studio·Gradle |
| 1 | 셸 개요 |
| 2 | 기본 WebView |
| 3 | Fragment |
| 4 | 멀티 윈도우·외부 링크 |
| 5 | 듀얼 WebView |
| 6 | AdMob |
| 7 | FCM |
| 8 | (이 글) 보안·설정 |

Kotlin WebView 셸은 **Activity/Fragment + 리소스 플래그 + WebViewClient 분기**로 대부분의 하이브리드 요구를 커버했다.
크로스플랫폼이 필요하면 [Flutter WebView App](../flutter-webview/README.md) 시리즈와 설계를 비교해 보면 된다.
