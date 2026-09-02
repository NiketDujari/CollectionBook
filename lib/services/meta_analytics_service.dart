import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MetaAnalyticsService {
  MetaAnalyticsService._();

  static final FacebookAppEvents _events = FacebookAppEvents();

  /// Call once when the application/session starts.
  static Future<void> initialize() async {
    try {
      await _events.activateApp();

      debugPrint(
        'META_ANALYTICS: App activated',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'META_ANALYTICS: initialization failed: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  static Future<bool> logEvent(
      String name, {
        Map<String, dynamic>? parameters,
      }) async {
    try {
      await _events.logEvent(
        name: name,
        parameters: parameters,
      );

      debugPrint(
        'META_ANALYTICS: $name',
      );

      return true;

    } catch (e, stackTrace) {
      debugPrint(
        'META_ANALYTICS: '
            '$name failed: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  static Future<void> logCustomerAdded() async {
    await logEvent(
      'customer_added',
    );
  }

  static Future<void> logLedgerEntryCreated() async {
    await logEvent(
      'ledger_entry_created',
    );
  }

  static Future<void> logPaymentRecorded() async {
    await logEvent(
      'payment_recorded',
    );
  }

  static Future<void> logLedgerShared() async {
    await logEvent(
      'ledger_shared',
    );
  }

  static Future<void> logReportGenerated() async {
    await logEvent(
      'report_generated',
    );
  }

  static Future<void> logFirstLedgerCreated() async {
    try {
      final box =
      Hive.box('collectionBook');

      final userId =
          FirebaseAuth
              .instance
              .currentUser
              ?.uid;

      if (
      userId == null ||
          userId.isEmpty
      ) {
        return;
      }

      final key =
          'meta-first-ledger-$userId';

      final alreadyLogged =
          box.get(key) == true;

      if (alreadyLogged) {
        return;
      }

      final logged =
      await logEvent(
        'first_ledger_created',
      );

      if (!logged) {
        return;
      }

      await box.put(
        key,
        true,
      );

    } catch (e) {
      debugPrint(
        'META_ANALYTICS: '
            'first ledger error: $e',
      );
    }
  }
}