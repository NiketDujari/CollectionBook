import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLockService {
  static const _storage = FlutterSecureStorage();

  static const _pinKey = 'app_lock_pin';
  static const _biometricKey = 'app_lock_biometric_enabled';

  static Future<bool> hasPin() async {
    final value = await _storage.read(key: _pinKey);
    return value != null && value.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    await _storage.write(
      key: _pinKey,
      value: pin,
    );
  }

  static Future<bool> verifyPin(String pin) async {
    final stored =
    await _storage.read(key: _pinKey);

    return stored == pin;
  }

  static Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
  }

  static Future<bool> isBiometricEnabled() async {
    return (
        await _storage.read(
          key: _biometricKey,
        )
    ) == 'true';
  }

  static Future<void> setBiometricEnabled(
      bool enabled,
      ) async {
    await _storage.write(
      key: _biometricKey,
      value: enabled ? 'true' : 'false',
    );
  }
}