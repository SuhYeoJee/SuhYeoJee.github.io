---
title: Kotlin WebView — AdMob 패턴
description: ""
date: 2026-06-17T12:00:00.000Z
preview: ""
draft: false
tags:
    - Kotlin
    - AdMob
    - WebView
categories:
    - Manual
series: ["Kotlin WebView 아카이브"]
---

## 개요

WebView 셸에 **전면(Interstitial)**·**앱 오픈(App Open)** 광고를 붙인 패턴이다.
광고 단위 ID는 `strings.xml`에 두고, 로드·표시는 `AdMobManager` 클래스로 모았다.

실제 ID 대신 Google이 문서에 제공하는 **테스트 ID**만 사용한다.

블로그용 스니펫은 전부 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.

---

## Gradle

`app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.google.android.gms:play-services-ads:22.6.0")
}
```

`AndroidManifest.xml`에 AdMob 앱 ID 메타데이터 (테스트용):

```xml
<application ...>
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-3940256099942544~3347511713"/>
</application>
```

---

## strings.xml (테스트 단위)

```xml
<resources>
    <!-- Google 공식 테스트 ID -->
    <string name="INTERSTITIALAD_CODE">ca-app-pub-3940256099942544/1033173712</string>
    <string name="OPENAD_CODE">ca-app-pub-3940256099942544/9257395921</string>
    <string name="ConsoleMsg">SHOW_INTERSTITIAL</string>
</resources>
```

`ConsoleMsg`는 웹이 `console.log`로 보내는 신호 문자열이었다. 운영에서는 명시적 bridge를 권장한다.

---

## bool.xml 플래그

```xml
<resources>
    <bool name="USE_INTERSTITIALAD">true</bool>
    <bool name="USE_OPENAD">true</bool>
</resources>
```

```kotlin
USE_INTERSTITIALAD = resources.getBoolean(R.bool.USE_INTERSTITIALAD)
USE_OPENAD = resources.getBoolean(R.bool.USE_OPENAD)
```

---

## AdMobManager

```kotlin
class AdMobManager(private val context: Context) {
    private var interstitialAd: InterstitialAd? = null
    private var appOpenAd: AppOpenAd? = null

    private val interstitialUnitId = context.getString(R.string.INTERSTITIALAD_CODE)
    private val openAdUnitId = context.getString(R.string.OPENAD_CODE)

    fun showInterstitialAd(activity: Activity) {
        val request = AdRequest.Builder().build()
        InterstitialAd.load(
            context,
            interstitialUnitId,
            request,
            object : InterstitialAdLoadCallback() {
                override fun onAdLoaded(ad: InterstitialAd) {
                    interstitialAd = ad
                    ad.show(activity)
                }
                override fun onAdFailedToLoad(error: LoadAdError) {
                    interstitialAd = null
                }
            }
        )
    }

    fun showOpenAd(activity: Activity) {
        val request = AdRequest.Builder().build()
        AppOpenAd.load(
            context,
            openAdUnitId,
            request,
            AppOpenAd.APP_OPEN_AD_ORIENTATION_PORTRAIT,
            object : AppOpenAd.AppOpenAdLoadCallback() {
                override fun onAdLoaded(ad: AppOpenAd) {
                    appOpenAd = ad
                    ad.show(activity)
                }
                override fun onAdFailedToLoad(error: LoadAdError) {
                    appOpenAd = null
                }
            }
        )
    }
}
```

매번 `load` 후 바로 `show`하는 단순 패턴이다. 프로덕션에서는 미리 로드해 두고 재사용하는 편이 낫다.

---

## MainActivity 연동

```kotlin
private lateinit var adMobManager: AdMobManager
private var loadOpenAdOnNextResume = false

override fun onCreate(savedInstanceState: Bundle?) {
    ...
    adMobManager = AdMobManager(this)
}

override fun onResume() {
    super.onResume()
    if (!USE_OPENAD) return
    if (loadOpenAdOnNextResume) {
        adMobManager.showOpenAd(this)
        loadOpenAdOnNextResume = false
    } else {
        loadOpenAdOnNextResume = true
    }
}
```

첫 `onResume`은 스킵하고, **두 번째 resume부터** 오픈 광고를 띄우는 트릭이었다 (콜드 스타트 직후 광고 방지).

전면 광고는 4편의 `onConsoleMessage` 또는 버튼 클릭에서 `showInterstitialAd`를 호출한다.

---

## FullScreenContentCallback

광고 닫힘·실패 시 참조를 null로 돌려 다음 로드를 준비한다.

```kotlin
interstitialAd?.fullScreenContentCallback = object : FullScreenContentCallback() {
    override fun onAdDismissedFullScreenContent() {
        interstitialAd = null
    }
    override fun onAdFailedToShowFullScreenContent(adError: AdError) {
        interstitialAd = null
    }
}
```

---

## 정책·UX 메모

- 스토어 정책: 콘텐츠와 무관한 과도한 전면 광고는 거절 사유가 될 수 있다.
- WebView 로딩 중 광고는 이탈을 유발한다. 오픈 광고는 앱 복귀 시점에만 등.
- 실제 배포 전 **테스트 ID → 본인 AdMob 단위 ID**로 교체하고, 디버그 빌드에 테스트 기기 등록을 사용한다.
