import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/legal_consent_service.dart';
import '../services/msg91_otp_service.dart';
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

  // Collection Book Brand Colors
  static const Color khadi = Color(0xFFEFE7D6);
  static const Color khadiLine = Color(0xFFD8CCB0);
  static const Color indigo = Color(0xFF2B3A67);
  static const Color indigoDeep = Color(0xFF182449);
  static const Color turmeric = Color(0xFFC98A2D);
  static const Color paper = Color(0xFFFBF8F1);
  static const Color charcoal = Color(0xFF2A2622);
  static const Color muted = Color(0xFF77705F);

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    legalAccepted = LegalConsentService.hasAcceptedCurrentVersion();
  }

  Future<void> sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!legalAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Terms & Conditions and review the Privacy Policy to continue.',
          ),
          backgroundColor: Color(0xFFA63D40), // Madder color from palette
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
      await LegalConsentService.markAccepted();
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

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFA63D40),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khadi,
      body: Stack(
        children: [
          // Background Line Texture (matching HTML body::before)
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundLinesPainter(),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      // Header Section
                      Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: turmeric.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: turmeric, width: 2.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.account_balance_wallet_outlined, 
                                color: turmeric, size: 40),
                            ),
                          ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms).fadeIn(),
                          
                          const SizedBox(height: 24),
                          
                          Text(
                            "Collection Book",
                            style: GoogleFonts.rozhaOne(
                              fontSize: 36,
                              color: indigoDeep,
                              height: 1,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            "Login securely to access your ledger.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 15,
                              color: muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Main Login Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: paper,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: khadiLine),
                          boxShadow: [
                            BoxShadow(
                              color: charcoal.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Enter Mobile Number",
                                style: GoogleFonts.ibmPlexSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => sendOTP(),
                                maxLength: 10,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: charcoal,
                                ),
                                decoration: InputDecoration(
                                  counterText: "",
                                  prefixIcon: const Icon(Icons.phone_android, color: turmeric),
                                  prefixText: "+91 ",
                                  prefixStyle: GoogleFonts.ibmPlexSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: turmeric,
                                  ),
                                  hintText: "00000 00000",
                                  hintStyle: TextStyle(color: muted.withOpacity(0.4)),
                                  filled: true,
                                  fillColor: khadi,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: turmeric, width: 2),
                                  ),
                                  errorStyle: GoogleFonts.ibmPlexSans(fontSize: 12),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter your mobile number";
                                  }
                                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                                    return "Enter a valid 10-digit number";
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Legal Consent
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: legalAccepted,
                                      activeColor: indigo,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: loading
                                          ? null
                                          : (value) {
                                        setState(() {
                                          legalAccepted = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          children: [
                                            Text(
                                              'I agree to the ',
                                              style: GoogleFonts.ibmPlexSans(
                                                fontSize: 12,
                                                color: charcoal,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.pushNamed(context, '/terms'),
                                              child: Text(
                                                'Terms',
                                                style: GoogleFonts.ibmPlexSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: indigo,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              ' & ',
                                              style: GoogleFonts.ibmPlexSans(fontSize: 12),
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
                                              child: Text(
                                                'Privacy Policy',
                                                style: GoogleFonts.ibmPlexSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: indigo,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Used to verify identity and identify account.',
                                          style: GoogleFonts.ibmPlexSans(
                                            fontSize: 10,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 32),

                              // Continue Button
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: loading || !legalAccepted ? null : sendOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: indigo,
                                    foregroundColor: paper,
                                    elevation: 4,
                                    shadowColor: indigo.withOpacity(0.3),
                                    disabledBackgroundColor: indigo.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: loading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: paper,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Get OTP",
                                              style: GoogleFonts.ibmPlexSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward_rounded, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        "TRUSTED BY 10,000+ MERCHANTS",
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: muted.withOpacity(0.5),
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 1000.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BackgroundLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8CCB0).withOpacity(0.35)
      ..strokeWidth = 1.0;

    const double step = 28.0;
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
