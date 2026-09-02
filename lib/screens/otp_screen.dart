import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../services/collection_book_auth_service.dart';
import '../services/legal_consent_service.dart';
import '../services/meta_analytics_service.dart';
import '../services/msg91_otp_service.dart';
import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/collection_book_auth_service.dart';
import '../services/msg91_otp_service.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'webview_screen.dart';

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
        ),
      );

      return;
    }

    if (loading) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      /*
     * Step 1:
     * Verify the OTP with MSG91.
     *
     * MSG91 returns its access token after successful verification.
     */
      final msg91AccessToken =
      await Msg91OtpService.instance.verifyOtp(otp);

      /*
     * Step 2:
     * Exchange the MSG91 access token for a Firebase custom token
     * and wait for Firebase Authentication to complete.
     */
      final userCredential =
      await CollectionBookAuthService.instance
          .signInWithMsg91AccessToken(
        msg91AccessToken,
      );

      /*
     * Step 3:
     * Confirm Firebase actually has a signed-in user before
     * leaving the OTP screen.
     */
      await userCredential.user?.reload();

      final firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception(
          'Firebase login did not complete.',
        );
      }

      await MetaAnalyticsService.logEvent(
        'registration_completed',
      );
      log(
        'Firebase login successful: '
            'uid=${firebaseUser.uid}, '
            'phone=${firebaseUser.phoneNumber}',
      );
      await LegalConsentService.saveLegalAcceptance()
         ;

      if (!mounted) {
        return;
      }

      /*
     * Step 4:
     * Remove LoginScreen and OTPScreen from the navigation stack.
     *
     * The "/" route opens AuthWrapper. AuthWrapper will see the
     * Firebase user and open StartupLoader -> WebViewScreen.
     */
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(
        '/',
            (route) => false,
      );
    } on FirebaseFunctionsException catch (error, stackTrace) {
      log(
        'MSG91 Firebase function failed',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'Unable to complete login.',
          ),
        ),
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      log(
        'Firebase authentication failed',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'Firebase authentication failed.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      log(
        'MSG91 login failed',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }


  // Future<void> verifyOTP() async {
  //   if (otpController.text.length != 6) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text("Enter a valid OTP")));
  //
  //     return;
  //   }
  //
  //   setState(() {
  //     loading = true;
  //   });
  //
  //   try {
  //     await _authService.verifyOTP(
  //       verificationId: verificationId,
  //
  //       otp: otpController.text,
  //     );
  //
  //     if (!mounted) return;
  //     await SessionService.resolveBusiness();
  //     await Future.delayed(const Duration(seconds: 3));
  //     print(SessionService.businessUid);
  //     print(SessionService.isEmployee);
  //     print(SessionService.permissions);
  //     showDialog(
  //       context: context,
  //
  //       barrierDismissible: false,
  //
  //       builder: (_) {
  //         return Dialog(
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(24),
  //           ),
  //
  //           child: Padding(
  //             padding: const EdgeInsets.all(30),
  //
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //
  //               children: [
  //                 CircleAvatar(
  //                   radius: 38,
  //
  //                   backgroundColor: Colors.green.shade100,
  //
  //                   child: Icon(Icons.check, size: 42, color: Colors.green),
  //                 ),
  //
  //                 const SizedBox(height: 20),
  //
  //                 Text(
  //                   "Verified",
  //
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 22,
  //
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 10),
  //
  //                 Text(
  //                   "Opening Collection Book...",
  //
  //                   textAlign: TextAlign.center,
  //
  //                   style: GoogleFonts.inter(),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     );
  //
  //     await Future.delayed(const Duration(milliseconds: 700));
  //     if (!mounted) return;
  //
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //
  //       MaterialPageRoute(builder: (_) => const WebViewScreen()),
  //
  //       (_) => false,
  //     );
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text(e.toString())));
  //       log(e.toString());
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         loading = false;
  //       });
  //     }
  //   }
  // }


  @override
  void initState() {
    super.initState();

    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

            colors: [Color(0xFFF5F9FF), Colors.white],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),

                child: Container(
                  padding: const EdgeInsets.all(28),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(28),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),

                        blurRadius: 30,

                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      const Center(child: AppLogo()).animate().fade().scale(),

                      const SizedBox(height: 24),

                      Text(
                        "Verify OTP",

                        textAlign: TextAlign.center,

                        style: GoogleFonts.poppins(
                          fontSize: 30,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "We've sent a verification code to",

                        textAlign: TextAlign.center,

                        style: GoogleFonts.inter(color: AppTheme.subtitle),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        widget.phone,

                        textAlign: TextAlign.center,

                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 35),
                      Center(
                        child: Pinput(
                          controller: otpController,

                          length: 6,

                          autofocus: true,

                          keyboardType: TextInputType.number,

                          defaultPinTheme: PinTheme(
                            width: 58,

                            height: 64,

                            textStyle: GoogleFonts.poppins(
                              fontSize: 24,

                              fontWeight: FontWeight.bold,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(18),

                              border: Border.all(color: AppTheme.border),
                            ),
                          ),

                          focusedPinTheme: PinTheme(
                            width: 58,

                            height: 64,

                            textStyle: GoogleFonts.poppins(
                              fontSize: 24,

                              fontWeight: FontWeight.bold,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(18),

                              border: Border.all(
                                color: AppTheme.primary,

                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

                      SizedBox(
                        height: 58,

                        child: ElevatedButton(
                          onPressed: loading ? null : verifyOTP,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,

                            foregroundColor: Colors.white,

                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),

                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),

                            child: loading
                                ? const SizedBox(
                                    key: ValueKey("loading"),

                                    width: 24,

                                    height: 24,

                                    child: CircularProgressIndicator(
                                      color: Colors.white,

                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    key: const ValueKey("verify"),

                                    mainAxisAlignment: MainAxisAlignment.center,

                                    children: [
                                      Text(
                                        "Verify OTP",

                                        style: GoogleFonts.poppins(
                                          fontSize: 17,

                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      const Icon(Icons.arrow_forward_rounded),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Text(
                        "Didn't receive the code?",

                        textAlign: TextAlign.center,

                        style: GoogleFonts.inter(
                          color: AppTheme.subtitle,

                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Center(
                        child: TextButton(
                          onPressed: canResend && !loading
                              ? () async {
                            setState(() {
                              loading = true;
                            });

                            try {
                              await Msg91OtpService.instance.resendOtp();

                              if (!mounted) return;

                              startTimer();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OTP sent again'),
                                ),
                              );
                            } catch (error) {
                              if (!mounted) return;

                              final message = error
                                  .toString()
                                  .replaceFirst('Exception: ', '');

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  loading = false;
                                });
                              }
                            }
                          }
                              : null,

                          child: Text(
                            canResend
                                ? "Resend OTP"
                                : "Resend in ${_secondsRemaining}s",

                            style: GoogleFonts.poppins(
                              color: AppTheme.primary,

                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
