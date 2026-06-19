---
title: React Native WebView — Firebase Analytics·웹 브릿지
description: ""
date: 2026-06-17T18:00:00.000Z
preview: ""
draft: false
tags:
    - React Native
    - Firebase
    - WebView
categories:
    - Manual
series: ["React Native WebView 아카이브"]
---

## 개요

**통합 템플릿**에서 `@react-native-firebase/analytics`로 앱·웹 이벤트를 한곳에 모은다.
웹 DOM에는 **injectJavaScript**로 리스너를 붙이고, 클릭 시 `window.ReactNativeWebView.postMessage`로 RN에 전달한다.

실 Firebase 프로젝트·`google-services.json` 실 ID는 글에 넣지 않는다.

---

## 설치

```bash
npm install @react-native-firebase/app @react-native-firebase/analytics
```

Firebase 콘솔에서 Android 앱을 등록하고 `android/app/google-services.json`을 둔다. 4·11편 project ID 검증과 맞춘다.

`.env`:

```bash
USE_FIREBASE=true
FIREBASE_BUTTON_EVENT=true
FIREBASE_BUTTON_CLASS=cta-primary,submit-btn
FIREBASE_PROJECT_ID=your-demo-project-id
```

---

## 버튼 클릭 inject

```javascript
import analytics from '@react-native-firebase/analytics';

handleButtonClick = () => {
  const classList = Config.FIREBASE_BUTTON_CLASS.split(',')
    .map((c) => `'${c.trim()}'`)
    .join(',');

  this.webViewRef.current.injectJavaScript(`
    (function() {
      const classes = [${classList}];
      classes.forEach(function(className) {
        document.querySelectorAll('.' + className).forEach(function(btn) {
          btn.addEventListener('click', function() {
            window.ReactNativeWebView.postMessage('ButtonClicked');
          });
        });
      });
    })();
    true;
  `);
};
```

`onLoadEnd`에서 DOM이 준비된 뒤 inject하는 것이 안전하다.

---

## onMessage → Analytics

```javascript
handleWebViewMessage = (event) => {
  const message = event.nativeEvent.data;
  if (message === 'ButtonClicked') {
    analytics().logEvent('web_button_clicked');
  }
};

<WebView
  onMessage={handleWebViewMessage}
  onLoadEnd={this.handleButtonClick}
/>
```

이벤트 이름·파라미터는 Firebase 콘솔 규칙에 맞게 정한다.

---

## console.log 후킹 (WebLog)

AdMob 트리거를 웹에서 `console.log`로 남기고 RN에서 가로채는 패턴도 있다 (9편).

```javascript
const injectedConsoleHook = `
(function() {
  var orig = console.log;
  console.log = function() {
    orig.apply(console, arguments);
    window.ReactNativeWebView.postMessage(JSON.stringify({
      type: 'console.log',
      payload: Array.from(arguments).join(' ')
    }));
  };
})();
`;

// WebView
injectedJavaScript={injectedConsoleHook}
```

```javascript
handleMessage = (event) => {
  try {
    const msg = JSON.parse(event.nativeEvent.data);
    if (msg.type === 'console.log' && msg.payload.includes('AD_TRIGGER')) {
      return true; // 9편: 전면 광고
    }
  } catch (_) {}
  return false;
};
```

가능하면 **명시적 postMessage 스키마**(`{ type: 'SHOW_AD' }`)를 권장한다. console 후킹은 디버그·레거시 호환용.

---

## USE_FIREBASE 플래그

```javascript
this.useFirebase = Config.USE_FIREBASE?.toLowerCase() === 'true';

if (this.useFirebase) {
  this.check_json(); // 4편 project ID 검증
}
```

Firebase off면 Analytics·inject를 건너뛰어 lean APK를 유지할 수 있다.

---

## Kotlin·Flutter 대비

| | RN | Kotlin |
|--|-----|--------|
| 웹 신호 | `postMessage` / inject | `onConsoleMessage` |
| 분석 | Firebase Analytics JS SDK 경유 | Firebase Android SDK |

웹과 앱 **이벤트 이름**을 맞추면 대시보드에서 비교하기 쉽다.
