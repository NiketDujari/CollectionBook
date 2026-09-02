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

  Future<void> saveDeviceToken(String phoneNumber, String role) async {
    await FirebaseMessaging.instance.requestPermission();
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken != null) {
      // Determine the correct collection based on the user's role
      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .set(
        {
          'fcmToken': fcmToken,
        },
        SetOptions(
          merge: true,
        ),
      );
    }
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