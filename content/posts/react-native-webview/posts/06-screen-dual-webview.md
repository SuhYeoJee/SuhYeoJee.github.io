---
title: React Native WebView — 스크린 듀얼 WebView
description: ""
date: 2026-06-17T17:00:00.000Z
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

**스크린 듀얼** / **통합 템플릿** 패턴: Stack에 **WebView1**(홈)·**WebView2**(외부) 두 스크린을 둔다.
외부 링크는 홈 도메인이 아니면 WebView1에서 로드를 막고, WebView2에 그 URL을 연다.

**통합 템플릿**(Analytics·AdMob 포함)과 같다: 이전 화면으로 돌아와도 **WebView1의 DOM·입력 상태가 유지**된다.

---

## WebView1 — handleNavigation

```javascript
handleNavigation = (event) => {
  const { navigation } = this.props;
  const { url } = event;

  if (!url.includes(this.homeDomain)) {
    navigation.navigate('WebView2', { url });
    return false;
  }
  return true;
};
```

```javascript
<WebView
  ref={this.webViewRef}
  source={{ uri: this.homeURL }}
  onShouldStartLoadWithRequest={this.handleNavigation}
  onNavigationStateChange={(navState) => {
    this.canGoBack = navState.canGoBack;
  }}
/>
```

- `return false` — WebView1에서 navigation 차단, WebView2로 이동
- `return true` — 같은 도메인, WebView1에서 계속 로드

---

## WebView2 — 뒤로가기

```javascript
class WebView2 extends React.Component {
  handleBackPress = () => {
    const { navigation } = this.props;
    if (this.canGoBack) {
      this.webViewRef.current.goBack();
      return true;
    }
    navigation.goBack(); // WebView1로 pop
    return true;
  };

  render() {
    const { url } = this.props.route.params;
    return (
      <WebView
        ref={this.webViewRef}
        source={{ uri: url }}
        onNavigationStateChange={(nav) => {
          this.canGoBack = nav.canGoBack;
        }}
      />
    );
  }
}
```

히스토리가 있으면 WebView2 내부 `goBack()`. 없으면 스택 pop.

---

## Navigator 등록

```javascript
<Stack.Navigator screenOptions={{ headerShown: false }}>
  <Stack.Screen name="WebView1" component={WebView1} />
  <Stack.Screen name="WebView2" component={WebView2} />
</Stack.Navigator>
```

---

## ref 배열 스택 (보조)

ref 배열로 동적 스택을 흉내 낼 수 있다: `webViewRefs[]`, `urls[]` state로 **여러 WebView 인스턴스**를 쌓는 패턴.

```javascript
const webViewRefs = useRef([]);
const [urls, setUrls] = useState([homeURL]);
const [canGoBacks, setCanGoBacks] = useState([false]);

// 외부 URL → urls.push(url), 새 WebView 렌더
// 뒤로가기 → 맨 위 ref goBack 또는 pop
```

Navigation 듀얼(5편)보다 복잡하지만 Navigation 스크린 수를 늘리지 않고 깊은 외부 체인을 처리할 때 쓴다. 실무에서는 스크린 듀얼 + ref 배열 스택 중 하나를 고른다.

---

## 듀얼 (상태 비유지)와 대비

| | 듀얼 (상태 비유지) | 스크린 듀얼 |
|--|-------|------|
| 외부 URL | WebView 교체·브라우저 | WebView2 스크린 |
| 홈 입력 | **유지 안 됨** | WebView1 **유지** |

초기 **외부 브라우저만** 템플릿과 비교하면, 스크린 듀얼이 앱 안 UX에 가깝다.

---

## 5편·통합 템플릿

- **Navigation Main/Sub (5편)**: 같은 도메인, Navigation 스택 중심
- **WebView1/2 (통합 템플릿)**: 상태 유지, Analytics·AdMob을 같은 App.js에 묶기 쉬움

Kotlin 듀얼 WebView(5편)과 같은 도메인 라우팅 / 홈 상태 유지 목표를 RN Navigation으로 옮긴 형태다.
