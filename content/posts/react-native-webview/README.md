# React Native WebView 아카이브

React Native **WebView 하이브리드 셸**의 설계·템플릿 진화(최소 셸 → Navigation 듀얼 → 통합 템플릿)를, **학습·공유 목적으로 독립 재구성**한 시리즈입니다.

별도 예제 프로젝트 없이, 각 글 본문에 **JavaScript 스니펫**을 포함합니다.

> 비공개 프로젝트 소스는 포함하지 않으며, URL·Firebase·AdMob 실 ID·내부 버전명은 사용하지 않습니다.

> **면책** — 학습·설계 패턴 공유 목적입니다. 예제는 데모 URL·Google 테스트 AdMob ID만 사용합니다. **본인이 관리·배포 권한이 있는 앱**에만 적용하고, Play 정책·AdMob·Firebase 약관을 준수하세요.

## 시리즈 목록

| # | 제목 | 상태 |
|---|------|------|
| 0 | [React Native WebView — Android·Metro 실행](./posts/00-setup-and-run.md) | 공개 |
| 1 | [React Native WebView — 셸 개요](./posts/01-series-intro.md) | 공개 |
| 2 | [React Native WebView — 최소 WebView 셸](./posts/02-minimal-webview-shell.md) | 공개 |
| 3 | [React Native WebView — 하드웨어 뒤로가기·종료](./posts/03-back-handler-exit.md) | 공개 |
| 4 | [React Native WebView — react-native-config (.env)](./posts/04-react-native-config.md) | 공개 |
| 5 | [React Native WebView — Navigation 듀얼 WebView](./posts/05-navigation-dual-webview.md) | 공개 |
| 6 | [React Native WebView — 스크린 듀얼 WebView](./posts/06-screen-dual-webview.md) | 공개 |
| 7 | [React Native WebView — 외부 링크·공유](./posts/07-external-links-share.md) | 공개 |
| 8 | [React Native WebView — Firebase Analytics·웹 브릿지](./posts/08-firebase-analytics-bridge.md) | 공개 |
| 9 | [React Native WebView — AdMob 전면·앱 오픈](./posts/09-admob-patterns.md) | 공개 |
| 10 | [React Native WebView — FCM·Notifee 푸시](./posts/10-fcm-notifee-push.md) | 공개 |
| 11 | [React Native WebView — 스플래시·보안·설정](./posts/11-splash-security-config.md) | 공개 |

## 관련 시리즈

- [Kotlin WebView 아카이브](../kotlin-webview/README.md)
- [Flutter WebView App](../flutter-webview/README.md)
- [Python 자동화 아카이브](../python-automation/README.md)

## 작성 원칙

- 비공개 코드·URL·Firebase·AdMob 실 ID·내부 버전명 미사용
- 기술 개념·설계 선택 중심
- 코드는 본문 인라인 스니펫 (RN 프로젝트에 붙여 넣기)
- 데모 URL: `https://example.com` 등 placeholder만 사용
- 포스트 제목은 `React Native WebView — …` 접두로 통일

## 상태

- 시리즈 글 모두 `draft: false` (공개)