# 01_basic_webview

Flutter WebView 시리즈 2편 예제.

- 하단 툴바 (뒤로 · 홈 · 맨위로 · 새로고침)
- 시스템 뒤로가기 + 종료 확인 다이얼로그
- 외부 https / `tel:` 링크는 외부 앱으로 열기
- 번들 HTML 데모 (`assets/demo/`)

## 실행

플랫폼 폴더가 없으면 먼저 생성한다.

```bash
cd examples/01_basic_webview
flutter create . --project-name basic_webview
flutter pub get
flutter run
```

## 설정

`lib/app_config.dart`

- `useBundledDemo = true` — 기본값, `assets/demo/index.html` 로드
- `useBundledDemo = false` — `homeUrl`의 실제 URL 로드, 다른 호스트는 외부 앱으로 연다

## 예제 출처

학습용으로 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.
