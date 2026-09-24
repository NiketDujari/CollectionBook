import 'dart:convert';
import 'package:collection_book/services/session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
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
          try {
            final value = await FirestoreService.get(
              payload["key"],
              webViewController: controller,
            );
            await _resolve(id, value);
          } catch (error) {
            print("Bridge GET error for key ${payload['key']}: $error");
            await _resolve(id, "[]");
          }
          break;

        case "set":
          try {
            String key = payload["key"];
            dynamic value = payload["value"];

            if (key == 'cb-profile-v1') {
              value = await _handleProfileLogoUpload(value);
            }

            await FirestoreService.set(
              key,
              value,
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

  Future<dynamic> _handleProfileLogoUpload(dynamic profileJson) async {
    try {
      final Map<String, dynamic> profile =
          jsonDecode(profileJson.toString()) as Map<String, dynamic>;
      final String? logoUrl = profile['logoUrl']?.toString();

      if (logoUrl != null && logoUrl.startsWith('data:image')) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Extract base64 part
          final String base64Str = logoUrl.split(',').last;
          final Uint8List bytes = base64Decode(base64Str);

          final storageRef = FirebaseStorage.instance
              .ref()
              .child('business_logos')
              .child('${user.uid}.jpg');

          final uploadTask = storageRef.putData(
              bytes, SettableMetadata(contentType: 'image/jpeg'));

          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();

          profile['logoUrl'] = downloadUrl;
          SessionService.businessLogoUrl = downloadUrl;

          // Inject base64 string directly into JS session so preview works immediately
          controller.runJavaScript("if (window.flutterSession) window.flutterSession.businessLogoBase64 = '$logoUrl';");

          return jsonEncode(profile);
        }
      }
    } catch (e) {
      print("Error handling profile logo upload: $e");
    }
    return profileJson;
  }
}
