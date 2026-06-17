import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "package:webview_flutter/webview_flutter.dart";

import "exit_dialog.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: DualWebViewShell()));
}

class DualWebViewShell extends StatefulWidget {
  const DualWebViewShell({super.key});

  @override
  State<DualWebViewShell> createState() => _DualWebViewShellState();
}

class _DualWebViewShellState extends State<DualWebViewShell> {
  static const _homeAsset = "assets/demo/index.html";

  late final WebViewController _primary;
  late final WebViewController _secondary;
  bool _showPrimary = true;

  @override
  void initState() {
    super.initState();
    _primary = _createController();
    _secondary = _createController();
    _primary.loadFlutterAsset(_homeAsset);
    _secondary.loadFlutterAsset(_homeAsset);
  }

  WebViewController _createController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigationRequest),
      );
  }

  WebViewController get _active =>
      _showPrimary ? _primary : _secondary;

  WebViewController get _inactive =>
      _showPrimary ? _secondary : _primary;

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url;

    if (url.startsWith("tel:") || url.startsWith("mailto:")) {
      _openExternally(url);
      return NavigationDecision.prevent;
    }

    final asset = assetPathFromUrl(url);
    if (asset != null) {
      _switchWebView(asset);
      return NavigationDecision.prevent;
    }

    if (url.startsWith("http://") || url.startsWith("https://")) {
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
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    if (shouldExit == true) {
      exitApp();
    }
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
        appBar: AppBar(
          title: const Text("dual_webview"),
          actions: [
            IconButton(
              tooltip: "홈",
              onPressed: () => _active.loadFlutterAsset(_homeAsset),
              icon: const Icon(Icons.home),
            ),
          ],
        ),
        body: SafeArea(
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
            ],
          ),
        ),
      ),
    );
  }
}
