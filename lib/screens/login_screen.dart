import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/legal_consent_service.dart';
import '../services/msg91_otp_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {


  final TextEditingController phoneController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool legalAccepted = false;

  @override
  void dispose() {
    phoneController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    legalAccepted =
        LegalConsentService
            .hasAcceptedCurrentVersion();
  }

  // Future<void> sendOTP() async {
  //   if (!_formKey.currentState!.validate()) {
  //     return;
  //   }
  //
  //   setState(() {
  //     loading = true;
  //   });
  //
  //   final phone = phoneController.text.trim();
  //
  //   try {
  //     await _authService.sendOTP(
  //       phoneNumber: "+91$phone",
  //
  //       onCodeSent: (verificationId) {
  //         setState(() {
  //           loading = false;
  //         });
  //
  //         Navigator.push(
  //           context,
  //
  //           MaterialPageRoute(
  //             builder: (_) =>
  //                 OTPScreen(verificationId: verificationId, phone: "+91$phone"),
  //           ),
  //         );
  //       },
  //
  //       onError: (message) {
  //         setState(() {
  //           loading = false;
  //         });
  //
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text(message)));
  //       },
  //     );
  //   } catch (e) {
  //     setState(() {
  //       loading = false;
  //     });
  //   }
  // }

  Future<void> sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!legalAccepted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Terms & Conditions and review the Privacy Policy to continue.',
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    final phone = phoneController.text.trim();

    try {
      await Msg91OtpService.instance.sendOtp(phone);
      await LegalConsentService
          .markAccepted();
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            phone: '+91$phone',
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

            colors: [Color(0xFFF5F9FF), Color(0xFFFFFFFF)],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),

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
                      const Center(
                        child: AppLogo(),
                      ).animate().fade(duration: 500.ms).scale(),



                      const SizedBox(height: 40),
                      Text(
                        "Mobile Number",

                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,

                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Form(
                        key: _formKey,

                        child: TextFormField(
                          controller: phoneController,

                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,

                          onFieldSubmitted: (_) {

                            sendOTP();

                          },

                          maxLength: 10,

                          decoration: InputDecoration(
                            counterText: "",

                            prefixIcon: const Icon(Icons.phone_android),

                            prefixText: "+91 ",

                            hintText: "Enter your mobile number",

                            filled: true,

                            fillColor: const Color(0xFFF8FAFC),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),

                              borderSide: BorderSide(color: AppTheme.border),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),

                              borderSide: BorderSide(
                                color: AppTheme.primary,

                                width: 2,
                              ),
                            ),
                          ),

                          validator: (value) {

                            if (value == null || value.trim().isEmpty) {

                              return "Please enter your mobile number";

                            }

                            if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {

                              return "Please enter a valid Indian mobile number";

                            }

                            return null;

                          },
                        ),
                      ).animate().fade().slideY(begin: .2),
                      const SizedBox(height: 18),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Checkbox(
                            value: legalAccepted,

                            activeColor: AppTheme.primary,

                            onChanged: loading
                                ? null
                                : (value) {
                              setState(() {
                                legalAccepted =
                                    value ?? false;
                              });
                            },
                          ),

                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsets.only(top: 10),

                              child: Wrap(
                                children: [
                                  const Text(
                                    'I agree to the ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/terms',
                                      );
                                    },

                                    child: Text(
                                      'Terms & Conditions',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight.w600,
                                        color:
                                        AppTheme.primary,
                                        decoration:
                                        TextDecoration
                                            .underline,
                                      ),
                                    ),
                                  ),

                                  const Text(
                                    ' and acknowledge that I have read the ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/privacy-policy',
                                      );
                                    },

                                    child: Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight.w600,
                                        color:
                                        AppTheme.primary,
                                        decoration:
                                        TextDecoration
                                            .underline,
                                      ),
                                    ),
                                  ),

                                  const Text('.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Your mobile number will be used to send and verify an OTP and to identify your Collection Book account.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          height: 1.4,
                          color: AppTheme.subtitle,
                        ),
                      ),
                      const SizedBox(height: 30),

                      SizedBox(

                        height: 58,

                        child: ElevatedButton(

                          onPressed:  loading || !legalAccepted
                              ? null
                              : sendOTP,

                          style: ElevatedButton.styleFrom(

                            elevation: 0,

                            backgroundColor: AppTheme.primary,

                            foregroundColor: Colors.white,

                            disabledBackgroundColor: AppTheme.primary.withOpacity(.7),

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

                                strokeWidth: 2,

                                color: Colors.white,

                              ),

                            )

                                : Row(

                              key: const ValueKey("button"),

                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [

                                Text(

                                  "Continue",

                                  style: GoogleFonts.poppins(

                                    fontSize: 17,

                                    fontWeight: FontWeight.w600,

                                  ),

                                ),

                                const SizedBox(width: 10),

                                const Icon(Icons.arrow_forward_rounded),

                              ],

                            ),

                          ),

                        ),

                      )

                          .animate()

                          .fade(delay: 300.ms)

                          .slideY(begin: .2),
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
