import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection_book/screens/locked_home.dart';
import 'package:collection_book/screens/login_screen.dart';
import 'package:collection_book/screens/security_settings_screen.dart';
import 'package:collection_book/screens/webview_screen.dart';
import 'package:collection_book/services/msg91_otp_service.dart';
import 'package:collection_book/services/notification_service.dart';
import 'package:collection_book/services/session_service.dart';
import 'package:collection_book/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:collection_book/legal/legal_content.dart';
import 'package:collection_book/screens/legal_document_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:collection_book/services/app_lock_service.dart';
import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'FCM background message: ${message.messageId}',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings =
  const Settings(
    persistenceEnabled: true,
  );
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );
  Msg91OtpService.instance.initialize();
  await Hive.initFlutter();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:
      Colors.transparent,

      statusBarIconBrightness:
      Brightness.light,

      statusBarBrightness:
      Brightness.dark,

      systemNavigationBarColor:
      Color(0xFFF7F7F7),

      systemNavigationBarIconBrightness:
      Brightness.dark,
    ),
  );


  await Hive.openBox("collectionBook");

  runApp(const CollectionBookApp());
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        if (
        snapshot.connectionState ==
            ConnectionState.waiting
        ) {
          log("waiting");
          return const SplashScreen();
        }

        if (snapshot.hasData) {
          log("has data");
          return const StartupLoader();
          // Replace HomeScreen with your existing dashboard widget name
        }

        return const LoginScreen();
      },
    );
  }
}
class StartupLoader extends StatefulWidget {
  const StartupLoader({super.key});

  @override
  State<StartupLoader> createState() => _StartupLoaderState();
}

class _StartupLoaderState extends State<StartupLoader> {

  late Future<bool> _future;

  @override
  void initState() {
    super.initState();

    _future = _initialize();
  }

  Future<bool> _initialize() async {
    final stopwatch =
    Stopwatch()..start();

    await SessionService.resolveBusiness();

    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint(
        'Notification initialization failed: $e',
      );
    }

    /*
   * Resolve app-lock state while the
   * splash screen is still visible.
   *
   * This prevents LockedHome from briefly
   * appearing just to determine whether
   * a PIN exists.
   */
    final bool hasAppLock =
    await AppLockService.hasPin();

    stopwatch.stop();

    const minDuration =
    Duration(seconds: 3);

    if (
    stopwatch.elapsed <
        minDuration
    ) {
      await Future.delayed(
        minDuration -
            stopwatch.elapsed,
      );
    }

    return hasAppLock;
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<bool>(
      future: _future,

      builder: (context, snapshot) {

        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor:
            const Color(0xFFEFE7D6),

            body: Center(
              child: Padding(
                padding:
                const EdgeInsets.all(32),

                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color:
                      Color(0xFF2B3A67),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    const Text(
                      'Unable to connect',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(0xFF182449),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Please check your internet '
                          'connection and try again.',
                      textAlign:
                      TextAlign.center,
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future =
                              _initialize();
                        });
                      },

                      child:
                      const Text(
                        'Retry',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final bool hasAppLock =
            snapshot.data ?? false;

/*
 * App lock enabled:
 * use LockedHome so lifecycle locking
 * continues to work.
 */
        if (hasAppLock) {
          return const LockedHome(
            initiallyLocked: true,
          );
        }

/*
 * No app lock:
 * completely bypass LockedHome.
 */
        return const WebViewScreen();
      },
    );
  }
}
class CollectionBookApp extends StatelessWidget {
const CollectionBookApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Collection Book',
  theme: ThemeData(

    scaffoldBackgroundColor: AppTheme.background,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTheme.primary,
    ),

    useMaterial3: true,

  ),
debugShowCheckedModeBanner: false,

initialRoute: '/',
routes: {
'/': (context) => const AuthWrapper(),
'/login': (context) => const LoginScreen(),
'/home': (context) => const AuthWrapper(),
  '/privacy-policy': (context) =>
  const LegalDocumentScreen(
    title: LegalContent.privacyPolicyTitle,
    content: LegalContent.privacyPolicy,
  ),

  '/terms': (context) =>
  const LegalDocumentScreen(
    title: LegalContent.termsTitle,
    content: LegalContent.termsAndConditions,
  ),
  '/security-settings': (context) =>
  const SecuritySettingsScreen(),
},
);
}
}
