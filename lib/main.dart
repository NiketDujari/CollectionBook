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
import 'package:collection_book/services/app_language_service.dart';
import 'package:collection_book/services/theme_service.dart';
import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options:
    DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'FCM background message: '
        '${message.messageId}',
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

  await Hive.openBox("collectionBook");
  ThemeService.instance.initialize();
  AppLanguageService.instance.initialize();

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
          return const SplashScreen(canNavigate: false,);
        }

        // Take everyone to StartupLoader, authenticated or not.
        return const StartupLoader();
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

  Future<void> _resolveBusinessWithRetry() async {
    const maxAttempts = 5;

    for (
    var attempt = 1;
    attempt <= maxAttempts;
    attempt++
    ) {
      try {
        debugPrint(
          'resolveBusiness attempt $attempt/$maxAttempts',
        );

        await SessionService.resolveBusiness();

        debugPrint(
          'resolveBusiness succeeded on attempt $attempt',
        );

        return;
      } on FirebaseException catch (
    e,
    stackTrace
    ) {
    debugPrint(
    'resolveBusiness Firebase error '
    'attempt=$attempt '
    'code=${e.code} '
    'message=${e.message}',
    );

    /*
       * Only retry errors that are expected
       * to be temporary.
       */
    final retryable =
    e.code == 'unavailable' ||
    e.code == 'deadline-exceeded' ||
    e.code == 'aborted' ||
    e.code == 'internal';

    if (
    !retryable ||
    attempt == maxAttempts
    ) {
    debugPrintStack(
    stackTrace: stackTrace,
    );

    rethrow;
    }

    /*
       * 500ms, 1s, 1.5s, 2s...
       */
    await Future.delayed(
    Duration(
    milliseconds:
    500 * attempt,
    ),
    );
    } catch (
    e,
    stackTrace
    ) {
    /*
       * Don't silently retry programming,
       * permission or application-state errors.
       */
    debugPrint(
    'resolveBusiness non-Firebase error: $e',
    );

    debugPrintStack(
    stackTrace: stackTrace,
    );

    rethrow;
    }
  }
  }


  Future<bool> _initialize() async {
    final stopwatch =
    Stopwatch()..start();

    /*
   * On a cold install/start Android networking
   * and Firestore may need a short moment before
   * the first remote request succeeds.
   *
   * Keep the splash visible and retry silently.
   */
    try {
      await _resolveBusinessWithRetry();
    } catch (e) {
      debugPrint('Business resolution failed: $e');
      // If it's a messaging error, we can ignore it and proceed.
      if (e.toString().contains('firebase_messaging')) {
        debugPrint('Ignoring messaging error during business resolution.');
      } else {
        rethrow;
      }
    }

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
    bool hasAppLock = false;
    try {
      hasAppLock = await AppLockService.hasPin();
    } catch (e) {
      debugPrint('AppLock initialization failed: $e');
    }

    stopwatch.stop();

    const minDuration =
    Duration(milliseconds: 100);

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
          return const SplashScreen(canNavigate: false,);
        }

        if (snapshot.hasError) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: isDark ? Colors.black : const Color(0xFFEFE7D6),

            body: SafeArea(
              top: false,
              child: Center(
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

                      if (snapshot.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
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
return ValueListenableBuilder<ThemeMode>(
  valueListenable: ThemeService.instance.themeMode,
  builder: (context, mode, child) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguageService.instance.currentLanguage,
      builder: (context, lang, child) {
        final isDark = mode == ThemeMode.dark;
        
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: isDark ? Colors.black : const Color(0xFFF7F7F7),
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'Collection Book',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const AuthWrapper(),
            '/privacy-policy': (context) => LegalDocumentScreen(
              title: AppLanguageService.instance.translate('privacy_policy'),
              content: LegalContent.privacyPolicy,
            ),
            '/terms': (context) => LegalDocumentScreen(
              title: AppLanguageService.instance.translate('terms_conditions'),
              content: LegalContent.termsAndConditions,
            ),
            '/security-settings': (context) => const SecuritySettingsScreen(),
          },
        );
      },
    );
  },
);
}
}
