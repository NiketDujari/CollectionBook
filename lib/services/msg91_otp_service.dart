import 'dart:developer';

import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

class Msg91OtpService {
  Msg91OtpService._();

  static final Msg91OtpService instance = Msg91OtpService._();

  static const String _widgetId = '36686a726b52303732353836';
  static const String _widgetToken = '559036T8vtZMZS96a7a15e1P1';

  String? _requestId;
  String? _phoneNumber;

  void initialize() {
    OTPWidget.initializeWidget(
      _widgetId,
      _widgetToken,
    );
  }

  Future<void> sendOtp(String tenDigitNumber) async {
    final normalizedNumber = tenDigitNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(normalizedNumber)) {
      throw Exception('Enter a valid 10-digit Indian mobile number.');
    }

    _phoneNumber = '+91$normalizedNumber';

    final rawResponse = await OTPWidget.sendOTP({
      'identifier': '91$normalizedNumber',
    });

    if (rawResponse is! Map) {
      throw Exception('Unexpected response received from MSG91.');
    }

    final response = Map<String, dynamic>.from(rawResponse!);

    if (response['type'] != 'success') {
      throw Exception(
        response['message']?.toString() ?? 'Unable to send OTP.',
      );
    }

    // The MSG91 Flutter SDK returns reqId in "message".
    final requestId = response['message']?.toString();

    if (requestId == null || requestId.isEmpty) {
      throw Exception('MSG91 did not return a request ID.');
    }

    _requestId = requestId;
  }

  Future<String> verifyOtp(String otp) async {
    if (_requestId == null) {
      throw Exception('Please request a new OTP.');
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      throw Exception('Enter the 6-digit OTP.');
    }

    final response = await OTPWidget.verifyOTP({
      'reqId': _requestId,
      'otp': otp,
    });

    if (response == null) {
      throw Exception('No response received from MSG91.');
    }

    if (response['type'] != 'success') {
      throw Exception(
        response['message']?.toString() ??
            'Incorrect or expired OTP.',
      );
    }

    // For your MSG91 Flutter Widget response,
    // "message" is the verified JWT access token.
    final message = response['message'];

    if (message is! String || message.trim().isEmpty) {
      throw Exception('MSG91 did not return an access token.');
    }

    return message.trim();
  }

  Future<void> resendOtp() async {
    if (_requestId == null) {
      throw Exception('Please request a new OTP.');
    }

    final rawResponse = await OTPWidget.retryOTP({
      // Default configuration: do not pass retryChannel.
      'reqId': _requestId,
    });

    if (rawResponse is! Map) {
      throw Exception('Unexpected resend response.');
    }

    final response = Map<String, dynamic>.from(rawResponse!);

    if (response['type'] != 'success') {
      throw Exception(
        response['message']?.toString() ?? 'Unable to resend OTP.',
      );
    }
  }
  String? get verifiedPhoneNumber => _phoneNumber;

  void clear() {
    _requestId = null;
    _phoneNumber = null;
  }
}