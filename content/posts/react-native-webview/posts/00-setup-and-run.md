---
title: React Native WebView — Android·Metro 실행
description: ""
date: 2026-06-17T14:00:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - Setup
    - Android
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

이 시리즈는 별도 예제 프로젝트 없이, 각 글 본문의 JavaScript 스니펫을 참고해 React Native 프로젝트에 붙여 넣는 방식이다.
2편 이후 WebView 셸을 따라 만들려면 Node.js·Android SDK·Metro만 갖추면 된다.

---

## Node.js

React Native 0.72 기준 **Node 18 LTS**를 권장한다. 설치 후 버전을 확인한다.

```bash
node --version
npm --version
```

---

## 프로젝트 생성

CLI로 새 프로젝트를 만든다. TypeScript 템플릿을 써도 되지만, 이 시리즈 스니펫은 **JavaScript** 기준이다.

```bash
npx @react-native-community/cli init WebViewShell --version 0.72.4
cd WebViewShell
```

2편 최소 셸에는 `react-native-webview`만 추가하면 된다.

```bash
npm install react-native-webview@^13.5.1
```

5편부터 Navigation·Config 등은 해당 편에서 패키지를 추가한다.

---

## Android 환경

[React Native Environment Setup](https://reactnative.dev/docs/environment-setup) 가이드대로 다음을 설치한다.

- JDK 17 (Android Studio Embedded JDK 사용 가능)
- Android Studio + Android SDK (API 33+)
- ANDROID_HOME 환경 변수 (Windows: `%LOCALAPPDATA%\Android\Sdk`)

에뮬레이터 또는 USB 디버깅이 켜진 실기기를 연결한다.

---

## 실행

터미널 1 — Metro 번들러:

```bash
npm start
```

터미널 2 — Android 빌드·설치:

```bash
npm run android
```

첫 빌드는 Gradle 의존성 다운로드로 시간이 걸릴 수 있다. **Run** 후 앱이 뜨면 `App.js`를 2편 스니펫으로 교체해 테스트한다.

---

## 자주 막히는 지점

| 증상 | 확인 |
|------|------|
| `SDK location not found` | `local.properties`에 `sdk.dir` 설정 |
| Metro 연결 실패 | 에뮬레이터와 PC가 같은 네트워크, `adb reverse` |
| WebView 빈 화면 | `AndroidManifest.xml`에 `INTERNET` 권한 |
| 네이티브 모듈 추가 후 크래시 | 앱 재빌드 (`npm run android`), Metro 캐시 리셋 |

```bash
npm start -- --reset-cache
```

---

## 이 시리즈와 다른 스택

| 항목 | React Native (이 시리즈) | Kotlin / Flutter |
|------|-------------------------|------------------|
| WebView | `react-native-webview` | `android.webkit` / `webview_flutter` |
| 설정 | `.env` + `react-native-config` | `strings.xml` / Dart 상수 |
| 듀얼 WebView | Navigation 스택 또는 스크린 2개 | FrameLayout swap |

Kotlin·Flutter WebView 시리즈와 병행하면 같은 하이브리드 목표를 스택별로 비교할 수 있다.
