---
title: React Native WebView — Navigation 듀얼 WebView
description: ""
date: 2026-06-17T16:30:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - WebView
    - Navigation
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

**Navigation 듀얼** 패턴: `@react-navigation/stack`으로 **Main**·**Sub** 두 스크린을 두고, 각각 WebView를 둔다.
외부 URL은 Main에서 가로채 Sub로 `navigate`하며 URL을 넘긴다.

Kotlin FrameLayout swap(5편), Flutter 듀얼 WebView(3편)과 같은 하이브리드 목표를 **RN Navigation**으로 구현한다.

---

## 의존성

```bash
npm install @react-navigation/native @react-navigation/stack
npm install react-native-screens react-native-safe-area-context
npm install react-native-gesture-handler react-native-config
```

`index.js` 최상단에 gesture-handler import가 필요하다.

```javascript
import 'react-native-gesture-handler';
```

---

## App.js — Stack Navigator

```javascript
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import Config from 'react-native-config';
import { SimpleWebView } from './src/WebView';

const Stack = createStackNavigator();

const App = () => (
  <NavigationContainer>
    <Stack.Navigator initialRouteName="Main" screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Main">
        {(props) => <SimpleWebView {...props} url_link={Config.HOMELINK} />}
      </Stack.Screen>
      <Stack.Screen name="Sub">
        {(props) => <SimpleWebView {...props} url_link="" />}
      </Stack.Screen>
    </Stack.Navigator>
  </NavigationContainer>
);

export default App;
```

- Main — `Config.HOMELINK`로 고정
- Sub — 빈 URL, `route.params.url_from_main`으로 수신 (아래)

---

## SimpleWebView — 도메인 라우팅

```javascript
import React, { useEffect, useState, useRef } from 'react';
import { WebView } from 'react-native-webview';
import { BackHandler } from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import Config from 'react-native-config';

export const SimpleWebView = ({ url_link }) => {
  const webViewRef = useRef(null);
  const [currentUrl, setCurrentUrl] = useState(url_link);
  const [canGoBack, setCanGoBack] = useState(false);
  const navigation = useNavigation();
  const route = useRoute();
  const isMain = route.name === 'Main';
  const homeDomain = Config.HOMELINK.split('//')[1].split('/')[0];

  useEffect(() => {
    if (!isMain && route.params?.url_from_main) {
      setCurrentUrl(route.params.url_from_main);
      webViewRef.current?.reload();
    }
  }, [route.params]);

  useEffect(() => {
    const onBack = () => {
      if (canGoBack && webViewRef.current) {
        webViewRef.current.goBack();
        return true;
      }
      if (!isMain) {
        navigation.navigate('Main');
        return true;
      }
      // Main: Modal/Alert 종료 (3편)
      return true;
    };
    const sub = BackHandler.addEventListener('hardwareBackPress', onBack);
    return () => sub.remove();
  }, [canGoBack, isMain]);

  const onShouldStartLoadWithRequest = (event) => {
    if (!isMain) return true;
    if (event.url?.includes(homeDomain)) return true;
    navigation.navigate('Sub', { url_from_main: event.url });
    return false;
  };

  return (
    <WebView
      ref={webViewRef}
      source={{ uri: currentUrl }}
      style={{ flex: 1 }}
      onShouldStartLoadWithRequest={onShouldStartLoadWithRequest}
      onNavigationStateChange={(nav) => setCanGoBack(nav.canGoBack)}
    />
  );
};
```

- `onShouldStartLoadWithRequest` + `return false` — Main WebView에 해당 URL 로드 **취소**
- Sub에서 히스토리 없으면 `navigate('Main')`으로 홈 복귀

---

## Main WebView 상태

Main 화면은 **unmount되지 않아** 내부 stack 히스토리가 유지된다. Sub만 push/pop하는 구조 (6편 스크린 듀얼과 대비).

---

## 6편과 비교

| | 5편 Navigation 듀얼 | 6편 스크린 2개 (상태 유지) |
|--|---------------------|----------------------|
| 외부 | `navigate('Sub')` | `navigate('WebView2', { url })` |
| 홈 상태 | Stack 아래 Main | WebView1 계속 **마운트** |
| Sub 복귀 | `navigate('Main')` | `navigation.goBack()` |

같은 도메인 라우팅, 다른 Navigation·상태 유지 특성.
