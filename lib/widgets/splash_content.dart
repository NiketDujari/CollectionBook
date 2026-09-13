import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashContent extends StatelessWidget {
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Collection Book Brand Colors
    const Color khadi = Color(0xFFEFE7D6);
    const Color indigoDeep = Color(0xFF182449);
    const Color turmeric = Color(0xFFC98A2D);

    return Material(
      color: khadi,
      child: Stack(
        children: [
          // Subtle texture
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
                  'CREDIT & LEDGER MANAGEMENT',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: turmeric,
                    letterSpacing: 2.5,
                  ),
                ),

                const SizedBox(height: 60),

                // Loading Indicator
                const SizedBox(
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
            ),
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
