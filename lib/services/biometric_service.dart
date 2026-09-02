import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth =
  LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      final canCheck =
      await _auth.canCheckBiometrics;

      final supported =
      await _auth.isDeviceSupported();

      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason:
        'Unlock Collection Book',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}