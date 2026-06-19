---
title: Kotlin WebView — Android Studio·Gradle 실행
description: ""
date: 2026-06-17T09:00:00.000Z
preview: ""
draft: false
tags:
    - Kotlin
    - Android
    - Gradle
categories:
    - Manual
series: ["Kotlin WebView 아카이브"]
---

## 개요

이 시리즈는 별도 예제 프로젝트 없이, 각 글 본문의 Kotlin·XML 스니펫을 참고해 Android Studio에서 직접 붙여 넣는 방식이다.
2편 이후 WebView 셸을 따라 만들려면 최소한의 빌드 환경만 갖추면 된다.

블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## Android Studio 설치

[Android Studio](https://developer.android.com/studio) 최신 안정판을 설치한다. 설치 마법사에서 **Android SDK**, **Android Virtual Device**를 함께 받는다.

설치 후 **SDK Manager**에서 아래를 확인한다.

- Android SDK Platform (API 33 이상 권장)
- Android SDK Build-Tools
- Android Emulator (실기기 없을 때)

---

## 새 프로젝트 생성

**Empty Activity** 템플릿으로 프로젝트를 만든다. 언어는 **Kotlin**, Minimum SDK는 **API 24** 정도면 이 시리즈 스니펫과 맞는다.

생성 직후 `app/build.gradle.kts`의 `compileSdk`·`minSdk`가 의도와 맞는지 확인한다.

```kotlin
android {
    namespace = "com.example.webviewshell"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.webviewshell"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
}
```

- `compileSdk` — 빌드 시 참조하는 API 수준
- `minSdk` — 설치 가능한 최소 Android 버전
- `targetSdk` — 런타임 동작 기준 (스토어 권장값에 맞춤)

---

## 의존성 (시리즈 공통)

WebView 셸 본편(2~5편)에는 AndroidX만으로 충분하다. 6~7편 AdMob·FCM은 해당 편에서 Gradle 블록을 추가한다.

```kotlin
dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}
```

---

## 인터넷 권한

WebView가 원격 URL을 열려면 `AndroidManifest.xml`에 권한이 필요하다.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application ...>
        ...
    </application>
</manifest>
```

데모 URL은 `https://example.com`처럼 공개 도메인만 사용한다. 실서비스·내부 전용 호스트는 글에 넣지 않는다.

---

## 실행 방법

1. Android Studio에서 프로젝트 열기
2. 상단 기기 선택 (에뮬레이터 또는 USB 디버깅 연결 실기기)
3. **Run** (▶) 또는 `Shift+F10`

Gradle Sync가 실패하면 **File → Sync Project with Gradle Files**를 먼저 실행한다. JDK는 Studio에 포함된 **Embedded JDK 17**을 쓰는 것이 무난하다.

---

## 디버깅 팁

- **Logcat** — `WebView`, `shouldOverrideUrlLoading` 등 태그로 URL 흐름 확인
- **Layout Inspector** — `FrameLayout`에 WebView가 동적으로 붙는 패턴(5편) 확인
- **네트워크** — 에뮬레이터는 PC와 동일 네트워크; 사내망 전용 URL은 실기기·VPN 환경에서만 테스트

---

## 이 시리즈와 Flutter WebView 시리즈

같은 “웹 한 장을 앱 껍데기로 감싼다”는 목표지만, 스택이 다르다.

| 항목 | Kotlin (이 시리즈) | Flutter ([Flutter WebView App](../flutter-webview/README.md)) |
|------|-------------------|-----------------------------------|
| UI 호스트 | Activity / Fragment | `MaterialApp` + 위젯 트리 |
| WebView API | `android.webkit.WebView` | `webview_flutter` / `inappwebview` |
| 설정 위치 | `res/values/strings.xml`, `bool.xml` | Dart 상수·환경 변수 |

Flutter [0편](../flutter-webview/posts/00-setup-and-run.md)과 함께 읽으면 하이브리드 앱 설계 선택지를 비교하기 좋다.
