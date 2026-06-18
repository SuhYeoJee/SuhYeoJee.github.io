# 03_dual_webview

WebViewController 두 개 + `Offstage` 전환 패턴. **기능 보완용이 아니라, 단일 컨트롤러 셸과 다른 형태의 템플릿 샘플**이다.

## 실행

```bash
cd examples/03_dual_webview
flutter create . --project-name dual_webview
flutter pub get
flutter run
```

## 핵심

- 링크 클릭 시 비활성 컨트롤러에 로드 → 컨트롤러 교체
- 뒤로가기: 현재 컨트롤러 → 이전 컨트롤러 순으로 `canGoBack()` 확인
