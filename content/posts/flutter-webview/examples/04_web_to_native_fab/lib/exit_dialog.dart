import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

Future<bool?> showExitDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("앱 종료"),
      content: const Text("앱을 종료하시겠습니까?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("아니오"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("예"),
        ),
      ],
    ),
  );
}

void exitApp() {
  if (Platform.isAndroid) {
    SystemNavigator.pop();
  } else {
    exit(0);
  }
}

/// 웹 URL 쿼리로 네이티브 UI 표시 여부를 판단한다.
///
/// 예: `index.html?feature=timer` → 타이머 FAB 노출
bool shouldShowTimerFab(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return uri.queryParameters["feature"] == "timer";
}
