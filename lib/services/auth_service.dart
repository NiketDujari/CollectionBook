import 'package:collection_book/services/session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {

  final FirebaseAuth _firebaseAuth =
      FirebaseAuth.instance;


  User? get currentUser =>
      _firebaseAuth.currentUser;


  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String message) onError,
  }) async {


    await _firebaseAuth.verifyPhoneNumber(

      phoneNumber: phoneNumber,


      verificationCompleted:
          (PhoneAuthCredential credential) async {

        await _firebaseAuth
            .signInWithCredential(credential);

      },


      verificationFailed:
          (FirebaseAuthException e) {

        onError(
          e.message ??
              "Phone verification failed",
        );

      },


      codeSent:
          (String verificationId,
          int? resendToken) {

        onCodeSent(
          verificationId,
        );

      },


      codeAutoRetrievalTimeout:
          (String verificationId) {},

    );

  }

  Future<void> saveDeviceToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    await FirebaseMessaging.instance.requestPermission();

    final fcmToken =
    await FirebaseMessaging.instance.getToken();

    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'fcmToken': fcmToken,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
        'accountPhone': user.phoneNumber,
      },
      SetOptions(merge: true),
    );
  }



  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {


    PhoneAuthCredential credential =
    PhoneAuthProvider.credential(

      verificationId: verificationId,

      smsCode: otp,

    );


    return await _firebaseAuth
        .signInWithCredential(
      credential,
    );

  }



  Future<void> logout() async {
    SessionService.employeePhone = null;
    await _firebaseAuth.signOut();

  }

}