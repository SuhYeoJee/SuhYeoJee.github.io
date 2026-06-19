---
title: React Native WebView — react-native-config (.env)
description: ""
date: 2026-06-17T16:00:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - Config
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

앱마다 홈 URL·기능 on/off를 바꾸려면 **`.env` 파일**과 `react-native-config`를 쓰는 **설정형 템플릿** 패턴이 편하다.
Kotlin의 `strings.xml` + `bool.xml`, Flutter의 상수 파일과 같은 역할이다.

---

## 설치

```bash
npm install react-native-config
```

`.env`는 **gitignore**에 두고, `.env.example`만 저장소에 둔다.

---

## .env 예시 (데모용)

```bash
HOMELINK=https://example.com
HOME_URL=https://example.com
HOME_DOMAIN=example.com

AFTERPOP=false
USE_ONCE_BACK=false
USE_SHARE_BTN=false
USE_FIREBASE=false
USE_ADMOB_INTERSTITIAL=false
USE_ADMOB_OPENAD=false
FIREBASE_CLOUD_MESSAGING=false
SPLASH_TIME=1.5
```

- `HOMELINK` / `HOME_URL` — 프로젝트마다 키 이름이 다름. 한쪽만 있으면 그 키를 사용
- 불리언 플래그는 JS에서 `"true"` 문자열과 `.toLowerCase() == "true"` 비교 권장

---

## JS에서 읽기

```javascript
import Config from 'react-native-config';

const homeUrl = Config.HOME_URL;
const useShare = Config.USE_SHARE_BTN?.toLowerCase() === 'true';
```

```javascript
// App.js — 2편 최소 셸 대체
import Config from 'react-native-config';

const App = () => (
  <WebView source={{ uri: Config.HOME_URL }} style={{ flex: 1 }} />
);
```

---

## Android 연동

`android/app/build.gradle` 상단:

```gradle
apply from: project(':react-native-config').projectDir.getPath() + "/dotenv.gradle"
```

`.env` 변경 후 **네이티브 재빌드**가 필요하다 (`npm run android`). Metro만 재시작해서는 Config 값이 갱신되지 않을 수 있다.

선택적으로 Gradle에서 `project.env.get("USE_FIREBASE")`로 Firebase 의존성을 조건부 추가할 수 있다 (11편).

---

## Firebase project ID 검증 (선택)

실서비스 전 `.env`의 `FIREBASE_PROJECT_ID`와 `google-services.json`의 projectId가 일치하는지 확인한다.

```javascript
import firebase from '@react-native-firebase/app';
import Config from 'react-native-config';

const checkFirebaseProject = () => {
  const fromEnv = Config.FIREBASE_PROJECT_ID;
  const fromJson = firebase.app().options.projectId;
  if (fromEnv !== fromJson) {
    Alert.alert('Firebase 프로젝트 불일치', `${fromEnv} vs ${fromJson}`);
  }
};
```

실 Firebase 프로젝트 ID는 글에 넣지 않는다. 8~11편에서 같은 검증을 재사용한다.

---

## 빌드 variant (참고)

스테이징·프로덕션 URL을 나누려면 `.env.staging`, `.env.production`과 Gradle flavor를 조합한다. 이 시리즈는 단일 `.env`만 다룬다.

---

## 5편 예고

Navigation 듀얼에서 `Config.HOMELINK`, `Config.AFTERPOP`을 5편 Navigation 듀얼 WebView와 함께 사용한다.
