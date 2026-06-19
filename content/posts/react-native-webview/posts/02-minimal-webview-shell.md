---
title: React Native WebView — 최소 WebView 셸
description: ""
date: 2026-06-17T15:00:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - WebView
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

이 편은 `react-native`와 `react-native-webview`만으로 **최소 템플릿** 셸을 만든다.
Navigation, Config, Firebase 등은 아직 넣지 않고, URL만 바꿔 동작을 확인한다.

---

## package.json (핵심)

```json
{
  "dependencies": {
    "react": "18.2.0",
    "react-native": "0.72.4",
    "react-native-webview": "^13.5.1"
  }
}
```

---

## AndroidManifest

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

`<application>` 안의 `MainActivity`와 `App` 등록은 CLI 생성 프로젝트에 기본 포함된다.

---

## App.js

```javascript
import React, { useRef, useState } from 'react';
import { WebView } from 'react-native-webview';

const HOME_URL = 'https://example.com';

const App = () => {
  const webViewRef = useRef(null);
  const [canGoBack, setCanGoBack] = useState(false);

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

- `source={{ uri }}` — 시작 URL
- `onNavigationStateChange` — `canGoBack` 갱신 (3편 뒤로가기용)
- `flex: 1` — WebView가 화면 전체를 채움

---

## WebView props (나중에 쓸 것)

2편에서는 다루지 않지만, 이후 편에서 쓸 주요 props를 미리 표로 정리한다.

| prop | 용도 |
|------|------|
| `onShouldStartLoadWithRequest` | URL 가로채기 (5~7편) |
| `onMessage` | 웹 → RN 메시지 (8~9편) |
| `injectedJavaScript` | 페이지 로드 후 JS 주입 (8편) |
| `javaScriptEnabled` | 기본 true, SPA 필수 |

---

## 3편·4편 예고

`canGoBack` state를 **BackHandler**와 연결하면 하드웨어 뒤로가기를 처리할 수 있다.
4편에서는 `HOME_URL`을 `.env` + `react-native-config`로 분리한다.
