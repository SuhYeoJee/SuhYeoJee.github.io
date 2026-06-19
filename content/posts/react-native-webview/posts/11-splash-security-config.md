---
title: React Native WebView — 스플래시·보안·설정
description: ""
date: 2026-06-17T19:30:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - Android
    - Security
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

마지막 편은 **스플래시**, **`.env` 배포 체크리스트**, **WebView·앱 보안**을 정리한다.
**통합 템플릿**은 `react-native-splash-screen` + `SPLASH_TIME`, Navigation 템플릿은 Android `SplashActivity`를 병행하기도 한다.

---

## react-native-splash-screen

```bash
npm install react-native-splash-screen
```

`.env`:

```bash
SPLASH_TIME=1.5
```

```javascript
import SplashScreen from 'react-native-splash-screen';

componentDidMount() {
  const sec = parseFloat(Config.SPLASH_TIME || '1') * 1000;
  setTimeout(() => SplashScreen.hide(), sec);
}
```

네이티브 스플래시 drawable·테마는 패키지 README대로 별도 설정한다.

---

## Android SplashActivity (Navigation 템플릿)

LAUNCHER Activity를 Splash로 두고, 짧은 delay 후 MainActivity(RN)로 넘긴다.

```java
// SplashActivity.java (스케치)
public class SplashActivity extends AppCompatActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    startActivity(new Intent(this, MainActivity.class));
    finish();
  }
}
```

`AndroidManifest.xml`에서 `SplashActivity`에 MAIN/LAUNCHER intent-filter, `MainActivity`는 exported true.

RN JS 스플래시와 **별도**로 네이티브 스플래시 hide 타이밍을 맞춘다.

---

## .env 체크리스트 (배포 전)

| 키 | 확인 |
|----|------|
| `HOME_URL` / `HOME_DOMAIN` | placeholder가 아닌 실 URL, 도메인 라우팅 일치 |
| `FIREBASE_PROJECT_ID` | `google-services.json`과 일치 (4편) |
| `ADMOB_*_ID` | 테스트 ID → 실 단위 ID (9편) |
| `USE_*` 플래그 | 불필요 기능 off |
| `.env` | gitignore, CI secret 주입 |

---

## Gradle 조건부 Firebase (별도 Android 모듈)

```gradle
if (project.env.get("USE_FIREBASE").toLowerCase() == "true") {
    implementation platform("com.google.firebase:firebase-bom:32.2.0")
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-messaging'
}
```

Firebase off APK 크기·권한을 줄인다. 실제 Android 앱 variant·모듈 구조는 프로젝트마다 다르지만, 조건부 의존성은 `app` 모듈 build.gradle에 두는 패턴이 일반적이다.

---

## WebView 보안

| 항목 | 권장 |
|------|------|
| `originWhitelist` | 필요 시 HTTPS만 |
| `onShouldStartLoadWithRequest` | `javascript:`, `file:` 등 차단 |
| `postMessage` | JSON schema 검증, 신뢰 도메인만 |
| `injectedJavaScript` | 최소 DOM만, 사용자 입력 URL inject 금지 |
| 디버그 | release에서 `WebView` remote debugging off |

---

## cleartext · network

Android 9+는 기본 HTTP 차단. `android:usesCleartextTraffic="false"`를 유지하고 HTTPS만 허용한다. Kotlin 8편 `network_security_config`와 같은 방향이다.

---

## 시리즈 요약

| # | 주제 |
|---|------|
| 0 | RN·Android 실행 |
| 1 | 셸·템플릿 개요 |
| 2 | 최소 WebView |
| 3 | BackHandler·종료 |
| 4 | react-native-config |
| 5 | Navigation 듀얼 WV |
| 6 | 스크린 듀얼 WV |
| 7 | Linking·Share |
| 8 | Firebase Analytics·브릿지 |
| 9 | AdMob |
| 10 | FCM·Notifee |
| 11 | (이 글) 스플래시·보안 |

**교차 참고**: [Kotlin WebView 시리즈](../kotlin-webview/README.md), [Flutter WebView 시리즈](../flutter-webview/README.md)와 같은 하이브리드 목표를 스택별로 비교할 수 있다.

React Native WebView 아카이브는 **`.env` + Navigation + postMessage** 중심으로 최소 템플릿부터 통합 템플릿까지 같은 골격을 쌓아 올린다.
