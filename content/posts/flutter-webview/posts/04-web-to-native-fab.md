---
title: Flutter WebView — URL로 네이티브 FAB 켜기
description: ""
date: 2026-06-16T16:00:00.000Z
preview: ""
draft: true
tags:
    - Flutter
    - FAB
    - NavigationDelegate
categories:
    - Manual
series: ["Flutter WebView 앱"]
---

# 개요

웹은 그대로 두고, **특정 페이지에서만** 네이티브 버튼을 보여주고 싶을 때가 있다.
타이머, 계산기, QR 같은 부가 기능 말이다.

예제: `examples/04_web_to_native_fab`

---

# 웹→앱 계약

웹과 앱이 약속할 신호가 필요하다. 이번 예제는 URL 쿼리를 쓴다.

```
index.html?feature=timer   → 타이머 FAB 표시
index.html               → FAB 숨김
```

특정 쿼리가 있을 때만 FAB를 켜는 방식이다. 이 예제에서는 `feature=timer` 를 쓴다.

---

# onPageStarted에서 FAB 상태 갱신

```dart
..setNavigationDelegate(
  NavigationDelegate(
    onPageStarted: (url) {
      setState(() => _showTimerFab = shouldShowTimerFab(url));
    },
    onNavigationRequest: _onNavigationRequest,
  ),
)
```

```dart
bool shouldShowTimerFab(String url) {
  final uri = Uri.tryParse(url);
  return uri?.queryParameters['feature'] == 'timer';
}
```

`onPageFinished`보다 `onPageStarted`가 체감상 더 빠르게 반응한다.

---

# FAB + 별도 화면

```dart
if (_showTimerFab)
  Positioned(
    right: 20,
    bottom: 24,
    child: FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TimerPage()),
        );
      },
      icon: const Icon(Icons.timer),
      label: const Text('타이머'),
    ),
  ),
```

`TimerPage`는 순수 Flutter 화면이다. WebView와 분리되어 있어서 유지보수가 쉽다.

---

# 데모 HTML

`index.html`에 링크 두 개:

- `index.html` — FAB 없음
- `index.html?feature=timer` — FAB 있음

웹 팀이 랜딩 페이지에 링크만 넣으면 앱 쪽 UI가 따라온다.

---

# 다른 신호 방식 (참고)

| 방식 | 장점 | 단점 |
|------|------|------|
| URL 쿼리 | 구현 간단 | 쿼리 노출, 캐시 이슈 |
| JS 채널 | 유연 | 웹·앱 양쪽 수정 |
| postMessage | 표준적 | 설정 번거로움 |

작은 랜딩 앱이면 쿼리만으로도 충분한 경우가 많다.

---

# 실행

```bash
cd examples/04_web_to_native_fab
flutter create . --project-name web_to_native_fab
flutter pub get
flutter run
```
