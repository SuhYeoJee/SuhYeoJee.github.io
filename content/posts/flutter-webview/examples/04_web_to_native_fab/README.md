# 04_web_to_native_fab

`onPageStarted`에서 URL 쿼리를 읽고 FAB를 노출한다.

## 실행

```bash
cd examples/04_web_to_native_fab
flutter create . --project-name web_to_native_fab
flutter pub get
flutter run
```

## 테스트

- `index.html` — FAB 없음
- `index.html?feature=timer` — 타이머 FAB 표시 → 타이머 화면 이동
