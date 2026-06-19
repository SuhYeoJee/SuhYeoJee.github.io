---
title: React Native WebView — AdMob 전면·앱 오픈
description: ""
date: 2026-06-17T18:30:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - AdMob
    - WebView
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

**통합 템플릿**에서 `react-native-google-mobile-ads`로 **전면(Interstitial)**·**앱 오픈(App Open)** 광고를 붙인다.
`.env` 플래그와 `AppState`로 노출 타이밍을 제어하고, 웹 `postMessage`/console 훅(8편)과 연동할 수 있다.

광고 단위 ID는 **Google 테스트 ID**만 사용한다.

---

## 설치

```bash
npm install react-native-google-mobile-ads
```

`app.json` 또는 `AndroidManifest`에 AdMob 앱 ID (데모):

```json
{
  "react-native-google-mobile-ads": {
    "android_app_id": "ca-app-pub-3940256099942544~3347511713"
  }
}
```

`.env`:

```bash
USE_ADMOB_INTERSTITIAL=true
USE_ADMOB_OPENAD=true
ADMOB_INTERSTITIAL_ID=ca-app-pub-3940256099942544/1033173712
ADMOB_OPENAD_ID=ca-app-pub-3940256099942544/9257395921
```

---

## AdmobService — 전면

```javascript
import { InterstitialAd, AdEventType } from 'react-native-google-mobile-ads';
import Config from 'react-native-config';

class AdmobService {
  constructor() {
    this.interstitial = InterstitialAd.createForAdRequest(
      Config.ADMOB_INTERSTITIAL_ID
    );
  }

  showInterstitial() {
    this.interstitial.load();
    this.interstitial.addAdEventListener(AdEventType.LOADED, () => {
      this.interstitial.show();
    });
  }
}

export default AdmobService;
```

데모는 load 후 show만 보여 준다. 프로덕션은 preload·캐시 패턴을 권장한다.

---

## AdmobOpenService — 앱 오픈

```javascript
import { AppOpenAd, AdEventType } from 'react-native-google-mobile-ads';
import Config from 'react-native-config';

class AdmobOpenService {
  constructor() {
    this.showOpenAdFlag = false;
    this.appOpenAd = AppOpenAd.createForAdRequest(Config.ADMOB_OPENAD_ID);
  }

  showAppOpenAd() {
    this.appOpenAd.load();
    this.appOpenAd.addAdEventListener(AdEventType.LOADED, () => {
      this.appOpenAd.show();
    });
  }
}

export default AdmobOpenService;
```

---

## AppState — 재개 시 앱 오픈

Kotlin `onResume`의 `LOAD_OPENAD` 플래그와 같은 의도다.

```javascript
import { AppState } from 'react-native';

handleAppStateChange = (nextAppState) => {
  if (!this.useAdmobOpenad) return;
  if (nextAppState === 'active') {
    if (this.adOpMob.showOpenAdFlag) {
      this.adOpMob.showOpenAdFlag = false;
      this.adOpMob.showAppOpenAd();
    } else {
      this.adOpMob.showOpenAdFlag = true;
    }
  }
};

componentDidMount() {
  AppState.addEventListener('change', this.handleAppStateChange);
}
```

첫 resume는 플래그만 세우고, 다음 active에서 앱 오픈을 띄우는 2단계 패턴.

---

## WebView onMessage 연동

```javascript
onMessage={(event) => {
  if (this.useAdmobInterstitial && this.weblog.handleMessage(event)) {
    if (this.useAdmobOpenad) {
      this.adOpMob.showOpenAdFlag = false;
    }
    this.adMob.showInterstitial();
  }
}}
```

웹 트리거와 앱 오픈 타이밍이 겹치지 않게 플래그를 조정한다.

---

## Kotlin 6편 대비

| | RN | Kotlin |
|--|-----|--------|
| SDK | `react-native-google-mobile-ads` | Play services Ads |
| 트리거 | postMessage / console | `onConsoleMessage` |
| 재개 광고 | `AppState` | `onResume` |

실 배포 전 App Open 정책·노출 빈도를 Play·AdMob 가이드에 맞춘다.

---

## 10편 예고

푸시(FCM)는 Analytics·AdMob과 함께 `@react-native-firebase/messaging` + Notifee로 처리한다.
