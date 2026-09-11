import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final bool canNavigate;
  const SplashScreen({super.key, this.canNavigate = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.canNavigate) {
      _startNavigation();
    }
  }

  void _startNavigation() {
    // Adding a slight delay to ensure animations can be seen
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // In a real app, you might navigate to AuthWrapper or Home
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Collection Book Brand Colors
    const Color khadi = Color(0xFFEFE7D6);
    const Color indigoDeep = Color(0xFF182449);
    const Color turmeric = Color(0xFFC98A2D);

    return Scaffold(
      backgroundColor: khadi,
      body: Stack(
        children: [
          // Subtle texture or background elements if needed
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated App Icon
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: turmeric.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: turmeric,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: turmeric.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/logo-transparent.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 800.ms)
                    .shimmer(delay: 1200.ms, duration: 1800.ms, color: Colors.white24),

                const SizedBox(height: 40),

                // Animated App Name
                Text(
                  'Collection Book',
                  style: GoogleFonts.rozhaOne(
                    fontSize: 42,
                    color: indigoDeep,
                    fontWeight: FontWeight.w400,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                // Animated Subtitle
                Text(
                  'CREDIT & LEDGER MANAGEMENT',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: turmeric,
                    letterSpacing: 2.5,
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 800.ms),

                const SizedBox(height: 60),

                // Loading Indicator
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(turmeric),
                  ),
                ).animate().fadeIn(delay: 1500.ms),
              ],
            ),
          ),

          // Footer attribution
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'TRUSTED BY LOCAL TRADERS',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: indigoDeep.withOpacity(0.4),
                  letterSpacing: 1.5,
                ),
              ),
            ).animate().fadeIn(delay: 1800.ms),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8CCB0)
      ..strokeWidth = 1.0;

    const double step = 28.0;
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
