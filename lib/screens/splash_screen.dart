import 'dart:async';
import 'package:collection_book/services/app_language_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final khadi = isDark ? const Color(0xFF000000) : const Color(0xFFEFE7D6);
    final indigoDeep = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF182449);
    final turmeric = isDark ? const Color(0xFFB08B4B) : const Color(0xFFC98A2D);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: khadi,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: khadi,
      ),
      child: Scaffold(
        backgroundColor: khadi,
        body: Stack(
          children: [
            // Subtle texture or background elements if needed
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.05 : 0.03,
                child: CustomPaint(
                  painter: GridPainter(
                    color: isDark ? Colors.white24 : const Color(0xFFD8CCB0),
                  ),
                ),
              ),
            ),
            Center(
              child: SafeArea(
                top: false,
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
                      AppLanguageService.instance.translate('app_sub'),
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: turmeric,
                        letterSpacing: 2.5,
                      ),
                    ).animate().fadeIn(delay: 800.ms, duration: 800.ms),

                    const SizedBox(height: 60),

                    // Loading Indicator
                    SizedBox(
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
            ),

            // Footer attribution
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: SafeArea(
                  top: false,
                  child: Text(
                    AppLanguageService.instance.translate('trusted_by'),
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: indigoDeep.withOpacity(isDark ? 0.6 : 0.4),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1800.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double step = 28.0;
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
