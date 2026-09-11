import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../services/collection_book_auth_service.dart';
import '../services/legal_consent_service.dart';
import '../services/meta_analytics_service.dart';
import '../services/msg91_otp_service.dart';

class OTPScreen extends StatefulWidget {
  final String phone;

  const OTPScreen({
    super.key,
    required this.phone,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController otpController = TextEditingController();
  bool loading = false;
  int _secondsRemaining = 60;
  Timer? _timer;
  bool canResend = false;

  // Collection Book Brand Colors
  static const Color khadi = Color(0xFFEFE7D6);
  static const Color khadiLine = Color(0xFFD8CCB0);
  static const Color indigo = Color(0xFF2B3A67);
  static const Color indigoDeep = Color(0xFF182449);
  static const Color turmeric = Color(0xFFC98A2D);
  static const Color paper = Color(0xFFFBF8F1);
  static const Color charcoal = Color(0xFF2A2622);
  static const Color muted = Color(0xFF77705F);

  void startTimer() {
    _secondsRemaining = 60;
    canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            canResend = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  Future<void> verifyOTP() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid 6-digit OTP'),
          backgroundColor: Color(0xFFA63D40),
        ),
      );
      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      final msg91AccessToken = await Msg91OtpService.instance.verifyOtp(otp);
      final userCredential = await CollectionBookAuthService.instance
          .signInWithMsg91AccessToken(msg91AccessToken);

      await userCredential.user?.reload();

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Firebase login did not complete.');
      }

      await MetaAnalyticsService.logEvent('registration_completed');
      log('Firebase login successful: uid=${firebaseUser.uid}');
      
      await LegalConsentService.saveLegalAcceptance();

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to complete login.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khadi,
      body: Stack(
        children: [
          // Background Line Texture
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundLinesPainter(),
            ),
          ),
          
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: indigoDeep),
                    onPressed: () => Navigator.pop(context),
                  ).animate().fadeIn().slideX(begin: -0.5, end: 0),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        children: [
                          // Header
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                "Verify OTP",
                                style: GoogleFonts.rozhaOne(
                                  fontSize: 36,
                                  color: indigoDeep,
                                  fontWeight: FontWeight.w400,
                                ),
                              ).animate().fadeIn(delay: 200.ms),
                              
                              const SizedBox(height: 12),
                          
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 16,
                                    color: muted,
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(text: "We've sent a code to\n"),
                                    TextSpan(
                                      text: widget.phone,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: charcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 400.ms),
                            ],
                          ),

                          const SizedBox(height: 48),

                          // OTP Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: paper,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: khadiLine),
                              boxShadow: [
                                BoxShadow(
                                  color: charcoal.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Pinput(
                                    controller: otpController,
                                    length: 6,
                                    autofocus: true,
                                    keyboardType: TextInputType.number,
                                    defaultPinTheme: PinTheme(
                                      width: 48,
                                      height: 56,
                                      textStyle: GoogleFonts.ibmPlexSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: charcoal,
                                      ),
                                      decoration: BoxDecoration(
                                        color: khadi,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: khadiLine),
                                      ),
                                    ),
                                    focusedPinTheme: PinTheme(
                                      width: 52,
                                      height: 60,
                                      textStyle: GoogleFonts.ibmPlexSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: turmeric,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: turmeric, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: turmeric.withValues(alpha: 0.1),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 40),

                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: loading ? null : verifyOTP,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: indigo,
                                      foregroundColor: paper,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: loading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: paper,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Verify & Login",
                                                style: GoogleFonts.ibmPlexSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.check_circle_outline_rounded, size: 20),
                                            ],
                                          ),
                                  ),
                                ),
                                
                                const SizedBox(height: 32),

                                // Resend Section
                                Column(
                                  children: [
                                    Text(
                                      "Didn't receive the code?",
                                      style: GoogleFonts.ibmPlexSans(
                                        color: muted,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: canResend && !loading
                                          ? () async {
                                              setState(() { loading = true; });
                                              try {
                                                await Msg91OtpService.instance.resendOtp();
                                                if (!mounted) return;
                                                startTimer();
                                                showToast('OTP sent again');
                                              } catch (error) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(error.toString())),
                                                );
                                              } finally {
                                                if (mounted) setState(() { loading = false; });
                                              }
                                            }
                                          : null,
                                      child: Text(
                                        canResend
                                            ? "Resend Code"
                                            : "Resend in ${_secondsRemaining}s",
                                        style: GoogleFonts.ibmPlexSans(
                                          color: canResend ? turmeric : muted,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: indigoDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class BackgroundLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8CCB0).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    const double step = 28.0;
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
