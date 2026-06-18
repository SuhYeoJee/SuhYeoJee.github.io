# webview_shell

`flutter-webview-hybrid` 통합 예제. 세 분리 예제의 패턴을 하나의 셸에 합쳤다.

- 듀얼 `WebViewController` + `Offstage` (셸 변형)
- 하단 툴바 (뒤로 · 홈 · 맨위로 · 새로고침)
- `?feature=timer` URL 쿼리 → 타이머 FAB → `TimerPage`
- 외부 `https://` / `tel:` → `url_launcher`

## 실행

```bash
cd examples/webview_shell
flutter create . --project-name webview_shell
flutter pub get
flutter run
```

Windows: 프로젝트 경로에 한글이 있으면 Gradle 빌드가 실패할 수 있다. ASCII 경로 권장.

## lib 구조

| 파일 | 역할 |
|------|------|
| `main.dart` | 셸 UI |
| `web_contract.dart` | URL·링크 분류 계약 |
| `app_config.dart` | 홈 URL / 데모 모드 |
| `exit_dialog.dart` | 종료 확인 |
| `timer_page.dart` | 네이티브 부가 화면 샘플 |

학습용으로 새로 작성했으며, 비공개 프로젝트 소스는 포함하지 않는다.
