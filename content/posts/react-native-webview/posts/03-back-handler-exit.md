---
title: React Native WebView — 하드웨어 뒤로가기·종료
description: ""
date: 2026-06-17T15:30:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - WebView
    - BackHandler
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

Android 하드웨어 뒤로가기는 WebView 히스토리와 앱 종료 사이를 나눠 처리해야 한다.
패턴은 **종료 Alert**, **한 번 더 goBack(afterpop)**, **Modal 확인** 등이 있다.

---

## 기본 패턴: Alert 종료

히스토리가 있으면 `goBack()`, 홈에서는 Alert로 종료를 확인한다.

```javascript
import React, { useRef, useState, useEffect } from 'react';
import { BackHandler, Alert } from 'react-native';
import { WebView } from 'react-native-webview';

const HOME_URL = 'https://example.com';

const App = () => {
  const webViewRef = useRef(null);
  const [canGoBack, setCanGoBack] = useState(false);

  useEffect(() => {
    const onBackPress = () => {
      if (canGoBack && webViewRef.current) {
        webViewRef.current.goBack();
        return true;
      }
      Alert.alert('앱 종료', '정말 종료하시겠습니까?', [
        { text: '취소', style: 'cancel' },
        { text: '종료', onPress: () => BackHandler.exitApp() },
      ]);
      return true;
    };

    const sub = BackHandler.addEventListener('hardwareBackPress', onBackPress);
    return () => sub.remove();
  }, [canGoBack]);

  return (
    <WebView
      ref={webViewRef}
      source={{ uri: HOME_URL }}
      style={{ flex: 1 }}
      onNavigationStateChange={(navState) =>
        setCanGoBack(!!navState.canGoBack)
      }
    />
  );
};

export default App;
```

- 항상 `return true` — 이벤트를 소비해 기본 동작(앱 즉시 종료) 방지
- `useEffect` 의존성 `[canGoBack]` — 히스토리 변화마다 핸들러가 최신 상태를 본다

---

## afterpop: 홈에서 한 번 더 goBack

홈에서 뒤로가기를 두 번 누르게 하려면 **한 번 더 `goBack()`**을 시도한다 (토스트·2단계 UX).

```javascript
let afterpop = true;

const onBackPress = () => {
  if (canGoBack && webViewRef.current) {
    webViewRef.current.goBack();
    return true;
  }
  if (afterpop && webViewRef.current) {
    webViewRef.current.goBack();
    afterpop = false;
    return true;
  }
  // ... Alert 종료
};
```

`.env`에 `AFTERPOP=true`를 두면 4~5편 **설정형 템플릿**·Navigation 듀얼에서 `Config.AFTERPOP`으로 읽는다.

---

## Modal 대안 (Navigation 템플릿)

Alert 대신 Modal로 종료 확인·브랜딩을 맞출 수 있다.

```javascript
import { Modal, View, Text, TouchableOpacity } from 'react-native';

const ExitModal = ({ visible, onCancel, onExit }) => (
  <Modal visible={visible} transparent animationType="fade">
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center',
      backgroundColor: 'rgba(0,0,0,0.5)' }}>
      <View style={{ backgroundColor: 'white', padding: 24, borderRadius: 8 }}>
        <Text>정말 종료하시겠습니까?</Text>
        <TouchableOpacity onPress={onCancel}><Text>취소</Text></TouchableOpacity>
        <TouchableOpacity onPress={onExit}><Text>종료</Text></TouchableOpacity>
      </View>
    </View>
  </Modal>
);
```

5편 Sub 화면에서 뒤로가면 `navigation.navigate('Main')`으로 **스택 pop** 대신 홈으로 복귀하는 패턴도 있다.

---

## USE_ONCE_BACK (한 번만 goBack)

`.env`의 `USE_ONCE_BACK`은 afterpop과 비슷하지만, 플래그를 한 번만 소비한 뒤 Alert로 종료한다.

```javascript
if (!canGoBack) {
  if (onceBackFlag) {
    onceBackFlag = false;
    webViewRef.current.goBack();
    return true;
  }
  Alert.alert(/* 종료 */);
  return true;
}
```

---

## iOS 참고

iOS에는 하드웨어 뒤로가기가 없다. 스와이프·Navigation 헤더는 `@react-navigation` 등 별도 처리. 이 글은 Android BackHandler 중심이다.
