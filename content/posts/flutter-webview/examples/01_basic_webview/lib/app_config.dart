/// 앱 설정.
///
/// [useBundledDemo]가 true면 번들된 HTML을 연다.
/// false면 [homeUrl]을 연다.
class AppConfig {
  static const bool useBundledDemo = true;

  /// 실제 서비스 URL로 바꿀 때 사용. useBundledDemo가 false일 때만 적용.
  static const String homeUrl = "https://example.com";

  static const String demoAsset = "assets/demo/index.html";
}
