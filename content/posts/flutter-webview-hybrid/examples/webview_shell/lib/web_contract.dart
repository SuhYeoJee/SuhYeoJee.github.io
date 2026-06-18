/// 웹 URL과 앱 동작 계약.
class WebContract {
  static bool isExternalScheme(String url) {
    return url.startsWith("tel:") || url.startsWith("mailto:");
  }

  static bool isRemoteHttp(String url) {
    return url.startsWith("http://") || url.startsWith("https://");
  }

  static bool isBundledHtml(String url) {
    return url.contains("appassets") ||
        url.contains("flutter_assets") ||
        url.endsWith(".html");
  }

  /// 가로채기 후 비활성 컨트롤러에 로드할 에셋 경로.
  static String? assetPathFromUrl(String url) {
    if (url.contains("page3.html")) return "assets/demo/page3.html";
    if (url.contains("page2.html")) return "assets/demo/page2.html";
    if (url.contains("index.html")) return "assets/demo/index.html";
    return null;
  }

  /// `?feature=timer` 일 때 네이티브 FAB 표시.
  static bool shouldShowTimerFab(String url) {
    final uri = Uri.tryParse(url);
    return uri?.queryParameters["feature"] == "timer";
  }
}
