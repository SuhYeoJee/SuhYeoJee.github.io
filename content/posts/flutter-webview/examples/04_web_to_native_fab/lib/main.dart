import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "package:webview_flutter/webview_flutter.dart";

import "exit_dialog.dart";
import "timer_page.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: FabWebViewShell()));
}

class FabWebViewShell extends StatefulWidget {
  const FabWebViewShell({super.key});

  @override
  State<FabWebViewShell> createState() => _FabWebViewShellState();
}

class _FabWebViewShellState extends State<FabWebViewShell> {
  static const _homeAsset = "assets/demo/index.html";

  late final WebViewController _controller;
  bool _showTimerFab = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _showTimerFab = shouldShowTimerFab(url));
          },
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..loadFlutterAsset(_homeAsset);
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url;

    if (url.startsWith("tel:") || url.startsWith("mailto:")) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }

    if (url.contains(".html") ||
        url.contains("appassets") ||
        url.contains("flutter_assets")) {
      return NavigationDecision.navigate;
    }

    if (url.startsWith("http://") || url.startsWith("https://")) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
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
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_showTimerFab)
                Positioned(
                  right: 20,
                  bottom: 24,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TimerPage()),
                      );
                    },
                    icon: const Icon(Icons.timer),
                    label: const Text("타이머"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
