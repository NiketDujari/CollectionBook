import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Android 13+ requires notification permission.
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Notification permission: ${settings.authorizationStatus}',
    );

    // Get this device's FCM token.
    final token = await messaging.getToken();

    if (token != null) {
      await _saveToken(token);
    }

    // FCM tokens can change, so always update Firestore.
    messaging.onTokenRefresh.listen((newToken) async {
      await _saveToken(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'Foreground FCM received: '
            '${message.notification?.title} - '
            '${message.notification?.body}',
      );
    });
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('Cannot save FCM token: user is not logged in');
      return;
    }

    final phone = user.phoneNumber;

    if (phone == null || phone.isEmpty) {
      debugPrint('Cannot save FCM token: user has no phone number');
      return;
    }

    // Firebase Auth phone number should already be:
    // +918124204482
    final normalizedPhone = phone.trim();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(normalizedPhone)
        .set(
      {
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    debugPrint(
      'FCM token saved at users/$normalizedPhone',
    );
  }
}