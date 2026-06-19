---
title: Kotlin WebView — FCM 푸시
description: ""
date: 2026-06-17T12:30:00.000Z
preview: ""
draft: false
tags:
    - Kotlin
    - FCM
    - Firebase
categories:
    - Manual
series: ["Kotlin WebView 아카이브"]
---

## 개요

WebView 셸에 **Firebase Cloud Messaging**을 붙여 마케팅·공지 푸시를 받는 패턴이다.
앱 UI는 웹이지만, 알림 채널·권한·토큰 관리는 네이티브 `FirebaseMessagingService`가 담당한다.

Firebase 콘솔·`google-services.json`은 프로젝트마다 새로 발급받으며, 이 글에는 실 키를 넣지 않는다.

블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## Gradle (프로젝트·앱)

루트 `build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

`app/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging-ktx")
}
```

`app/google-services.json`은 Firebase 콘솔에서 패키지명에 맞게 내려받아 둔다.

---

## AndroidManifest

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<application ...>
    <service
        android:name=".FCMService"
        android:exported="false">
        <intent-filter>
            <action android:name="com.google.firebase.MESSAGING_EVENT" />
        </intent-filter>
    </service>
</application>
```

API 33+에서는 런타임에 알림 권한을 요청해야 한다.

```kotlin
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
    requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
}
```

---

## FCMService

```kotlin
class FCMService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // 서버에 토큰 등록 (데모에서는 로그만)
        Log.d("FCM", "new token: $token")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        val title = remoteMessage.notification?.title ?: return
        val body = remoteMessage.notification?.body ?: return
        showNotification(title, body)
    }

    private fun showNotification(title: String, body: String) {
        val channelId = "default"
        val manager = NotificationManagerCompat.from(this)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "General",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            manager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        if (ActivityCompat.checkSelfPermission(
                this, Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        manager.notify(1, notification)
    }
}
```

- **포그라운드**에서 data-only 메시지는 `notification` payload가 없을 수 있어 분기 처리가 필요하다.
- 알림 탭 시 `MainActivity`로 진입; 딥링크 URL을 `Intent` extra로 넘기면 WebView `loadUrl`과 연결할 수 있다.

---

## MainActivity에서 토큰 확인 (선택)

```kotlin
FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
    if (task.isSuccessful) {
        Log.d("FCM", "token: ${task.result}")
    }
}
```

웹에 토큰을 넘기려면 `@JavascriptInterface`로 bridge를 두는 방법이 있다. 보안상 노출 범위를 최소화한다.

---

## 데이터 메시지 vs 알림 메시지

| 유형 | 앱 상태 | 동작 |
|------|---------|------|
| notification | 백그라운드 | 시스템 트레이 표시 (기본) |
| notification | 포그라운드 | `onMessageReceived`에서 직접 UI |
| data only | 모든 상태 | 항상 `onMessageReceived` |

운영 캠페인은 콘솔에서 보내고, 개발 중에는 Firebase Console **Messaging** 테스트 전송을 쓴다.

---

## WebView와의 관계

푸시는 네이티브 레이어 기능이다. 웹만 배포해도 알림 문구는 FCM payload에서 바꿀 수 있지만, **아이콘·채널·권한**은 앱 업데이트가 필요하다.
React Native·Flutter 템플릿에서도 같은 분리가 반복된다.
