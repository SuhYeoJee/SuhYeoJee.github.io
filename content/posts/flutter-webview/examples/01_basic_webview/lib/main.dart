import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "package:webview_flutter/webview_flutter.dart";

import "app_config.dart";
import "exit_dialog.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: WebViewShell()));
}

class WebViewShell extends StatefulWidget {
  const WebViewShell({super.key});

  @override
  State<WebViewShell> createState() => _WebViewShellState();
}

class _WebViewShellState extends State<WebViewShell> {
  late final WebViewController _controller;
  late final Uri? _homeUri;

  @override
  void initState() {
    super.initState();
    _homeUri = AppConfig.useBundledDemo ? null : Uri.parse(AppConfig.homeUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigationRequest),
      );

    if (AppConfig.useBundledDemo) {
      _controller.loadFlutterAsset(AppConfig.demoAsset);
    } else {
      _controller.loadRequest(_homeUri!);
    }
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url;

    if (url.startsWith("tel:") || url.startsWith("mailto:")) {
      _openExternally(url);
      return NavigationDecision.prevent;
    }

    if (AppConfig.useBundledDemo) {
      if (_isBundledAssetNavigation(url)) {
        return NavigationDecision.navigate;
      }
      if (url.startsWith("http://") || url.startsWith("https://")) {
        _openExternally(url);
        return NavigationDecision.prevent;
      }
      return NavigationDecision.navigate;
    }

    final host = Uri.parse(url).host;
    final homeHost = _homeUri!.host;
    if (host.isNotEmpty && host != homeHost) {
      _openExternally(url);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  bool _isBundledAssetNavigation(String url) {
    return url.contains("appassets") ||
        url.contains("flutter_assets") ||
        url.endsWith(".html");
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }

    if (!mounted) return false;
    final shouldExit = await showExitDialog(context);
    if (shouldExit == true) {
      exitApp();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: WebViewWidget(controller: _controller)),
              _BottomToolbar(
                onBack: _handleBack,
                onHome: () {
                  if (AppConfig.useBundledDemo) {
                    _controller.loadFlutterAsset(AppConfig.demoAsset);
                  } else {
                    _controller.loadRequest(_homeUri!);
                  }
                },
                onScrollTop: () {
                  _controller.runJavaScript(
                    "window.scrollTo({top: 0, behavior: 'smooth'});",
                  );
                },
                onReload: _controller.reload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  const _BottomToolbar({
    required this.onBack,
    required this.onHome,
    required this.onScrollTop,
    required this.onReload,
  });

  final Future<bool> Function() onBack;
  final VoidCallback onHome;
  final VoidCallback onScrollTop;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade200,
      child: SizedBox(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: "뒤로",
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            IconButton(
              tooltip: "홈",
              onPressed: onHome,
              icon: const Icon(Icons.home),
            ),
            IconButton(
              tooltip: "맨 위로",
              onPressed: onScrollTop,
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              tooltip: "새로고침",
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
