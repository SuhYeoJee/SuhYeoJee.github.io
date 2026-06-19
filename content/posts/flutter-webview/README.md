# Flutter WebView 하이브리드 앱 시리즈

랜딩 페이지를 감싸는 WebView 앱 템플릿을 만들며 익힌 패턴을, **학습·공유 목적으로 독립 재구현**하는 시리즈입니다.

> 비공개 프로젝트 소스는 포함하지 않으며, URL·도메인·내부 버전명은 사용하지 않습니다.

> **면책** — 학습·설계 패턴 공유 목적입니다. 예제는 데모 HTML·placeholder URL만 사용합니다. **본인이 관리·배포 권한이 있는 앱**에만 적용하고, Play 정책·Firebase·AdMob 약관을 준수하세요.

## 시리즈 목록

| # | 제목 | 예제 | 상태 |
|---|------|------|------|
| 0 | [Flutter — 설치와 예제 실행](./posts/00-setup-and-run.md) | — | 공개 |
| 1 | [Flutter WebView — 앱 복습](./posts/01-series-intro.md) | — | 공개 |
| 2 | [Flutter WebView — 툴바와 뒤로가기](./posts/02-basic-webview.md) | [01_basic_webview](./examples/01_basic_webview/) | 공개 |
| 3 | [Flutter WebView — 듀얼 WebView (컨트롤러 두 개)](./posts/03-dual-webview.md) | [03_dual_webview](./examples/03_dual_webview/) | 공개 |
| 4 | [Flutter WebView — URL로 네이티브 FAB 켜기](./posts/04-web-to-native-fab.md) | [04_web_to_native_fab](./examples/04_web_to_native_fab/) | 공개 |
| 5 | [Flutter WebView — inappwebview에서 webview_flutter로](./posts/05-inappwebview-migration.md) | — | 공개 |
| 6 | [Flutter WebView — 네이티브 부가 기능 붙이기](./posts/06-native-addons.md) | (4편 타이머 참고) | 공개 |

## 예제 프로젝트

```
examples/
  01_basic_webview/      ← 2편
  03_dual_webview/       ← 3편
  04_web_to_native_fab/  ← 4편, 6편(타이머)
```

각 폴더에서 `flutter create .` 후 `flutter run`. README 참고.

## 관련 시리즈

- [Kotlin WebView 아카이브](../kotlin-webview/README.md)
- [React Native WebView 아카이브](../react-native-webview/README.md)
- [Python 자동화 아카이브](../python-automation/README.md)
- [Vue 3 아카이브](../vue-personal/README.md)

## 작성 원칙

- 비공개 코드·URL·도메인·내부 버전명 미사용
- 포스트 1개 ↔ 예제 1개 (5·6편은 개념·변형 정리)
- 실행 가능한 최소 단위로 분리
- 포스트 제목은 `Flutter` / `Flutter WebView — …` 접두로 통일

## 상태

- 시리즈 글 모두 `draft: false` (공개)
