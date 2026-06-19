---
title: React Native WebView — 외부 링크·공유
description: ""
date: 2026-06-17T17:30:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - WebView
    - Linking
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

WebView 안 특정 URL은 OS로 넘긴다. 대표적으로 **Play Store** 링크는 `Linking.openURL`로 연다.
**공유 FAB**는 현재 페이지 URL을 `Share` API로 공유한다.

초기 **외부 브라우저만** 템플릿은 외부 URL을 항상 브라우저로 연다. **통합 템플릿**(스크린 듀얼)은 WebView/스크린 분리로 처리한다 (6편).

---

## Play Store · 스토어 링크

```javascript
import { Linking } from 'react-native';

const handleNavigation = (event) => {
  const { url } = event;

  if (url.includes('play.google')) {
    Linking.openURL(url);
    return false;
  }

  // 6편: 외부 도메인 → WebView2
  if (!url.includes(homeDomain)) {
    navigation.navigate('WebView2', { url });
    return false;
  }
  return true;
};
```

`Linking.canOpenURL(url)`로 열 수 있는지 확인할 수 있다 (iOS는 `Info.plist` URL scheme 화이트리스트 필요).

---

## tel: · mailto:

```javascript
if (url.startsWith('tel:') || url.startsWith('mailto:')) {
  Linking.openURL(url);
  return false;
}
```

Kotlin `handleIntent`의 `tel:` 처리와 같은 의도다.

---

## 공유 버튼 (ShareBTN)

`USE_SHARE_BTN=true`일 때만 표시. 스크롤 시 FAB를 숨기는 UX도 흔하다.

```javascript
import { Share, TouchableOpacity, Image } from 'react-native';

const ShareButton = ({ currentURL }) => (
  <TouchableOpacity
    style={{ position: 'absolute', bottom: 16, right: 16 }}
    onPress={() => Share.share({ message: currentURL })}
  >
    <Image source={require('./share-icon.png')} style={{ width: 48, height: 48 }} />
  </TouchableOpacity>
);
```

```javascript
// WebView1 render 안
{useShareBtn && showButton && (
  <ShareButton currentURL={this.currentURL} />
)}
```

- `currentURL` — `onNavigationStateChange`의 `navState.url` 갱신
- `showButton` — `onScroll` + `scrollEventThrottle`로 스크롤 중 숨김 (선택)

---

## 외부 브라우저만 패턴

아래처럼 외부 도메인을 전부 브라우저로 보내는 **외부 브라우저만** 템플릿도 있다:

```javascript
if (!url.includes(homeDomain)) {
  Linking.openURL(url);
  return false;
}
```

앱 안 UX보다 단순하지만, 스토어·결제 등 OS 앱으로 넘기기엔 충분할 때가 있다.

---

## 8편 예고

웹 버튼 클릭 등은 **웹 → RN 브릿지**로 `postMessage`를 쓴다 (Firebase Analytics, AdMob 트리거).
