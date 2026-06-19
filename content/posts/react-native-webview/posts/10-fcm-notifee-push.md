---
title: React Native WebView — FCM·Notifee 푸시
description: ""
date: 2026-06-17T19:00:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - FCM
    - Notifee
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

**통합 템플릿**에서 `@react-native-firebase/messaging`으로 FCM 토큰·메시지를 받고, **포그라운드** 알림은 `@notifee/react-native`로 표시한다.

백그라운드는 notification payload 설계가 중요하다. Kotlin 7편 FCMService와 같은 개념을 RN 패키지로 옮긴다.

---

## 설치

```bash
npm install @react-native-firebase/app @react-native-firebase/messaging
npm install @notifee/react-native
```

`.env`:

```bash
FIREBASE_CLOUD_MESSAGING=true
```

`google-services.json`과 Android `POST_NOTIFICATIONS` 권한(API 33+)을 확인한다.

---

## FCMService.js

```javascript
import messaging from '@react-native-firebase/messaging';
import notifee from '@notifee/react-native';

class FCMService {
  static async requestUserPermission() {
    const authStatus = await messaging().requestPermission();
    const enabled =
      authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
      authStatus === messaging.AuthorizationStatus.PROVISIONAL;

    if (enabled) {
      const token = await messaging().getToken();
      console.log('FCM token:', token);
      FCMService.handleForegroundMessages();
    }
  }

  static handleForegroundMessages() {
    messaging().onMessage(async (remoteMessage) => {
      await notifee.displayNotification({
        title: remoteMessage.notification?.title,
        body: remoteMessage.notification?.body,
      });
    });
  }

  static async createNotificationChannel() {
    await notifee.createChannel({
      id: 'default',
      name: 'Default Channel',
    });
  }
}

export default FCMService;
```

---

## App.js에서 호출

```javascript
import FCMService from './FCMService';

componentDidMount() {
  if (Config.FIREBASE_CLOUD_MESSAGING?.toLowerCase() === 'true') {
    FCMService.createNotificationChannel();
    FCMService.requestUserPermission();
  }
}
```

---

## 알림 탭 → WebView 딥링크 (참고)

Notifee `pressAction` 또는 `messaging().onNotificationOpenedApp`에서 URL extra를 읽어 WebView `loadUrl`에 넘길 수 있다.

```javascript
messaging().onNotificationOpenedApp((remoteMessage) => {
  const url = remoteMessage.data?.url;
  if (url) {
    // navigation 또는 webViewRef.loadUrl(url)
  }
});
```

데모 URL은 placeholder만 사용하고, 실서비스 도메인은 `.env`로 분리한다.

---

## data-only vs notification

| payload | 포그라운드 | 백그라운드 |
|---------|-----------|-----------|
| notification | `onMessage` → Notifee 표시 가능 | OS 알림 |
| data only | 항상 `onMessage` | `setBackgroundMessageHandler` 필요 |

백그라운드 data handler는 **index.js 최상단**에 등록해야 headless JS가 동작한다. 편의상 notification payload를 쓰는 경우가 많다.

---

## Kotlin 7편 대비

| | RN (Notifee) | Kotlin |
|--|--------------|--------|
| 포그라운드 UI | Notifee API | NotificationCompat |
| 토큰 | `messaging().getToken()` | `onNewToken` |

같은 FCM payload를 쓰더라도 **표시·채널·권한**은 플랫폼별로 맞춘다.
