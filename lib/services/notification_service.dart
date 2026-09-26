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

  static bool _initializing = false;

  static Future<void> initialize() async {
    if (_initializing) {
      debugPrint('NotificationService: initialization already in progress, skipping...');
      return;
    }
    _initializing = true;

    try {
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
    } finally {
      _initializing = false;
    }
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

    final type = message.data['type'];
    final isOnboarding = type == 'onboarding';
    final isEngagement = type == 'engagement';

    final channel = (isEngagement || isOnboarding)
        ? _engagementChannel
        : _transactionChannel;

    final defaultTitle = (isEngagement || isOnboarding) ? 'Collection Book' : 'New Transaction Alert!';
    final titleText = notification.title ?? defaultTitle;
    final bodyText = (notification.body ?? '').replaceAll(RegExp(r'</?[^>]+>'), '');

    String? bannerDrawable;
    if (isOnboarding) {
      bannerDrawable = 'engagement_banner';
    } else if (!isEngagement) {
      bannerDrawable = 'notification_banner';
    }

    final styleInfo = bannerDrawable != null
        ? BigPictureStyleInformation(
            DrawableResourceAndroidBitmap(bannerDrawable),
            largeIcon: const DrawableResourceAndroidBitmap('splash_logo'),
            contentTitle: titleText,
            summaryText: bodyText,
            htmlFormatContentTitle: true,
            htmlFormatSummaryText: true,
          )
        : null;

    try {
      await _localNotifications.show(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .remainder(1000000),

        title: titleText,

        body: bodyText,

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

            largeIcon:
            const DrawableResourceAndroidBitmap('splash_logo'),

            styleInformation:
            styleInfo,

            visibility:
            NotificationVisibility.public,

            category:
            AndroidNotificationCategory.reminder,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Local notification display with banner failed: $e');
      // Fallback display without BigPictureStyle if image resource fails on device
      try {
        await _localNotifications.show(
          id: DateTime.now()
              .millisecondsSinceEpoch
              .remainder(1000000),

          title: titleText,

          body: bodyText,

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
      } catch (fallbackError) {
        debugPrint('Fallback local notification failed: $fallbackError');
      }
    }
  }
}