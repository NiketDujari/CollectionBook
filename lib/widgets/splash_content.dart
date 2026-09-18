import 'package:collection_book/services/app_language_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashContent extends StatelessWidget {
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final khadi = isDark ? const Color(0xFF000000) : const Color(0xFFEFE7D6);
    final indigoDeep = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF182449);
    final turmeric = isDark ? const Color(0xFFB08B4B) : const Color(0xFFC98A2D);

    return Material(
      color: khadi,
      child: Stack(
        children: [
          // Subtle texture
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
                  // App Icon (Matches final state of SplashScreen)
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
                  ),

                  const SizedBox(height: 40),

                  // App Name
                  Text(
                    'Collection Book',
                    style: GoogleFonts.rozhaOne(
                      fontSize: 42,
                      color: indigoDeep,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    AppLanguageService.instance.translate('app_sub'),
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: turmeric,
                      letterSpacing: 2.5,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loading Indicator
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(turmeric),
                    ),
                  ),
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
            ),
          ),
        ],
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
