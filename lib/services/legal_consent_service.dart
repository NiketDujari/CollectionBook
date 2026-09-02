import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

class LegalConsentService {
  static const String currentVersion =
      '2026-08-12';

  static const String _acceptedKey =
      'legal-accepted-version';

  static Future<void> markAccepted()
  async {
    final box =
    Hive.box('collectionBook');

    await box.put(
      _acceptedKey,
      currentVersion,
    );
  }

  static bool hasAcceptedCurrentVersion() {
    final box =
    Hive.box('collectionBook');

    return box.get(_acceptedKey) ==
        currentVersion;
  }

  static Future<void> clear() async {
    final box =
    Hive.box('collectionBook');

    await box.delete(_acceptedKey);
  }
  static Future<void> saveLegalAcceptance()
  async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null ||
        user.phoneNumber == null) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.phoneNumber)
        .set(
      {
        'termsAcceptedVersion':
        LegalConsentService
            .currentVersion,

        'privacyPolicyAcknowledgedVersion':
        LegalConsentService
            .currentVersion,

        'legalAcceptedAt':
        FieldValue
            .serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }
}