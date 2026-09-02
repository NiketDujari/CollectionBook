import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollectionBookAuthService {
  CollectionBookAuthService._();

  static final CollectionBookAuthService instance =
  CollectionBookAuthService._();

  Future<UserCredential> signInWithMsg91AccessToken(
      String accessToken,
      ) async {
    final function = FirebaseFunctions.instanceFor(
      region: 'asia-south1',
    ).httpsCallable('exchangeMsg91Token');

    final result = await function.call({
      'accessToken': accessToken,
    });

    final customToken =
    result.data['firebaseCustomToken']?.toString();

    if (customToken == null || customToken.isEmpty) {
      throw Exception('Firebase login token was not returned.');
    }

    return FirebaseAuth.instance.signInWithCustomToken(customToken);
  }
}