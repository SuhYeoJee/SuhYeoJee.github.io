# Flutter WebView 하이브리드 앱 시리즈



랜딩 페이지를 감싸는 WebView 앱 템플릿을 만들며 익힌 패턴을, **학습·공유 목적으로 독립 재구현**하는 시리즈입니다.



> 회사에서 사용하던 소스코드는 비공개이며, 이 시리즈의 예제 코드는 별도로 새로 작성합니다.



## 시리즈 목록



| # | 제목 | 예제 | 상태 |

|---|------|------|------|

| 0 | [Flutter 설치와 예제 실행](./posts/00-setup-and-run.md) | — | 초안 |
| 1 | [Flutter WebView 앱 복습](./posts/01-series-intro.md) | — | 초안 |

| 2 | [Flutter WebView 기본 — 툴바와 뒤로가기](./posts/02-basic-webview.md) | [01_basic_webview](./examples/01_basic_webview/) | 초안 |

| 3 | [Flutter 듀얼 WebView — 컨트롤러 두 개](./posts/03-dual-webview.md) | [03_dual_webview](./examples/03_dual_webview/) | 초안 |

| 4 | [Flutter WebView — URL로 네이티브 FAB 켜기](./posts/04-web-to-native-fab.md) | [04_web_to_native_fab](./examples/04_web_to_native_fab/) | 초안 |

| 5 | [Flutter WebView — inappwebview에서 webview_flutter로](./posts/05-inappwebview-migration.md) | — | 초안 |

| 6 | [Flutter WebView — 네이티브 부가 기능 붙이기](./posts/06-native-addons.md) | (4편 타이머 참고) | 초안 |



## 예제 프로젝트



```

examples/

  01_basic_webview/      ← 2편

  03_dual_webview/       ← 3편

  04_web_to_native_fab/  ← 4편, 6편(타이머)

```



각 폴더에서 `flutter create .` 후 `flutter run`. README 참고.



## 작성 원칙



- 회사 코드·URL·도메인·내부 버전명 미사용

- 포스트 1개 ↔ 예제 1개 (5·6편은 개념·변형 정리)

- 실행 가능한 최소 단위로 분리


