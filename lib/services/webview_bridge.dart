import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import 'firestore_service.dart';

class WebViewBridge {
  final WebViewController controller;

  WebViewBridge(this.controller);

  Future<void> handleMessage(String message) async {
    try {
      final request = jsonDecode(message);

      final int id = request["id"];
      final String method = request["method"];
      final Map payload = request["payload"] ?? {};

      switch (method) {
        case "get":
          final value = await FirestoreService.get(payload["key"],webViewController: controller,);

          await _resolve(id, value);

          break;

        case "set":
          try {
            await FirestoreService.set(
              payload["key"],
              payload["value"],
            );

            await _resolve(id, true);
          } catch (error) {
            await _resolve(
              id,
              {
                'success': false,
                'error': error.toString(),
              },
            );
          }

          break;

        case "remove":
          await FirestoreService.remove(payload["key"]);

          await _resolve(id, true);

          break;

        case "clear":
          await FirestoreService.clear();

          await _resolve(id, true);

          break;

        default:
          await _reject(id, "Unknown method");
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _resolve(int id, dynamic value) async {
    final json = jsonEncode(value);

    await controller.runJavaScript("""

window.flutterResolve(
$id,
$json
);

""");
  }

  Future<void> _reject(int id, String error) async {
    final escaped = jsonEncode(error);

    await controller.runJavaScript("""

window.flutterReject(
$id,
$escaped
);

""");
  }
}
