import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "package:webview_flutter/webview_flutter.dart";

import "app_config.dart";
import "exit_dialog.dart";
import "timer_page.dart";
import "web_contract.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: WebViewShell()));
}

/// 듀얼 WebView + 툴바 + URL 기반 FAB를 묶은 하이브리드 셸.
class WebViewShell extends StatefulWidget {
  const WebViewShell({super.key});

  @override
  State<WebViewShell> createState() => _WebViewShellState();
}

class _WebViewShellState extends State<WebViewShell> {
  late final WebViewController _primary;
  late final WebViewController _secondary;
  late final Uri? _homeUri;

  bool _showPrimary = true;
  bool _showTimerFab = false;

  @override
  void initState() {
    super.initState();
    _homeUri = AppConfig.useBundledDemo ? null : Uri.parse(AppConfig.homeUrl);
    _primary = _createController();
    _secondary = _createController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHome(onBoth: true));
  }

  WebViewController _createController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() => _showTimerFab = WebContract.shouldShowTimerFab(url));
          },
          onNavigationRequest: _onNavigationRequest,
        ),
      );
  }

  WebViewController get _active => _showPrimary ? _primary : _secondary;

  WebViewController get _inactive => _showPrimary ? _secondary : _primary;

  void _loadHome({bool onBoth = false}) {
    if (AppConfig.useBundledDemo) {
      if (onBoth) {
        _primary.loadFlutterAsset(AppConfig.demoAsset);
        _secondary.loadFlutterAsset(AppConfig.demoAsset);
      } else {
        _active.loadFlutterAsset(AppConfig.demoAsset);
      }
      return;
    }
    final uri = _homeUri!;
    if (onBoth) {
      _primary.loadRequest(uri);
      _secondary.loadRequest(uri);
    } else {
      _active.loadRequest(uri);
    }
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url;

    if (WebContract.isExternalScheme(url)) {
      _openExternally(url);
      return NavigationDecision.prevent;
    }

    if (AppConfig.useBundledDemo) {
      final asset = WebContract.assetPathFromUrl(url);
      if (asset != null) {
        _switchWebView(asset);
        return NavigationDecision.prevent;
      }
      if (WebContract.isRemoteHttp(url)) {
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

  void _switchWebView(String? assetPath) {
    setState(() => _showPrimary = !_showPrimary);
    if (assetPath != null) {
      _active.loadFlutterAsset(assetPath);
    }
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  Future<void> _handleBack() async {
    if (await _active.canGoBack()) {
      await _active.goBack();
      _switchWebView(null);
      return;
    }
    if (await _inactive.canGoBack()) {
      _switchWebView(null);
      return;
    }

    if (!mounted) return;
    final shouldExit = await showExitDialog(context);
    if (shouldExit == true) exitApp();
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Offstage(
                      offstage: !_showPrimary,
                      child: WebViewWidget(controller: _primary),
                    ),
                    Offstage(
                      offstage: _showPrimary,
                      child: WebViewWidget(controller: _secondary),
                    ),
                    if (_showTimerFab)
                      Positioned(
                        right: 20,
                        bottom: 24,
                        child: FloatingActionButton.extended(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TimerPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.timer),
                          label: const Text("타이머"),
                        ),
                      ),
                  ],
                ),
              ),
              _BottomToolbar(
                onBack: _handleBack,
                onHome: () => _loadHome(),
                onScrollTop: () {
                  _active.runJavaScript(
                    "window.scrollTo({top: 0, behavior: 'smooth'});",
                  );
                },
                onReload: _active.reload,
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

  final Future<void> Function() onBack;
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
