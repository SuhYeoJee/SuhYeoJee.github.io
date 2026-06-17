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

String? assetPathFromUrl(String url) {
  if (url.contains("page3.html")) return "assets/demo/page3.html";
  if (url.contains("page2.html")) return "assets/demo/page2.html";
  if (url.contains("index.html")) return "assets/demo/index.html";
  return null;
}
