import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {

  static final FlutterLocalNotificationsPlugin
  _localNotifications =
  FlutterLocalNotificationsPlugin();

  /*
   * Transactional notifications:
   * ledger entries, payments, etc.
   */
  static const AndroidNotificationChannel
  _transactionChannel =
  AndroidNotificationChannel(
    'collection_book_high',
    'Collection Book Notifications',
    description:
    'Ledger entries, payments and account notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /*
   * Scheduled engagement notifications.
   *
   * New channel ID is intentional.
   */
  static const AndroidNotificationChannel
  _engagementChannel =
  AndroidNotificationChannel(
    'collection_book_engagement_v1',
    'Business Reminders',
    description:
    'Helpful reminders to keep your business ledger updated',
    importance:
    Importance.max,
    playSound:
    true,
    enableVibration:
    true,
  );

  static const AndroidNotificationChannel
  _channel =
  AndroidNotificationChannel(
    'collection_book_high',
    'Collection Book Notifications',
    description:
    'Ledger entries, payments and business notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    final messaging =
        FirebaseMessaging.instance;

    await initializeLocalNotifications();

    final settings =
    await messaging.requestPermission(
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

    /*
     * Firebase does NOT automatically display
     * notification messages while the app
     * is in foreground.
     */
    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) async {
        debugPrint(
          'Foreground FCM received: '
              '${message.data}',
        );

        await showRemoteNotification(
          message,
        );
      },
    );
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

    // Use UID as the document ID for consolidated user profile.
    final uid = user.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(
      {
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
        'accountPhone': phone.trim(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  static Future<void>
  initializeLocalNotifications() async {
    const androidSettings =
    AndroidInitializationSettings(
      'ic_notification',
    );

    const initializationSettings =
    InitializationSettings(
      android:
      androidSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    final androidPlugin =
    _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin
        ?.createNotificationChannel(
      _transactionChannel,
    );

    await androidPlugin
        ?.createNotificationChannel(
      _engagementChannel,
    );
  }

  static Future<void> showRemoteNotification(
      RemoteMessage message,
      ) async {
    final notification =
        message.notification;

    if (notification == null) {
      return;
    }

    final isEngagement =
        message.data['type'] ==
            'engagement';

    final channel =
    isEngagement
        ? _engagementChannel
        : _transactionChannel;

    await _localNotifications.show(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .remainder(1000000),

      title:
      notification.title ??
          'Collection Book',

      body:
      notification.body ?? '',

      notificationDetails:
      NotificationDetails(
        android:
        AndroidNotificationDetails(
          channel.id,
          channel.name,

          channelDescription:
          channel.description,

          importance:
          Importance.max,

          priority:
          Priority.max,

          playSound:
          true,

          enableVibration:
          true,

          icon:
          'ic_notification',

          visibility:
          NotificationVisibility.public,

          category:
          AndroidNotificationCategory.reminder,
        ),
      ),
    );
  }
}