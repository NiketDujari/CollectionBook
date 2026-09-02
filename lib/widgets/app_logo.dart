import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final TextStyle? textStyle;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showText = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Icon container with background styling
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFC98A2D).withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFC98A2D),
              width: 3,
            ),
          ),
          child: Center(
            child:  Image.asset(
              'assets/logo-transparent.png', // Replace with your actual image path
              width: 100,
              height: 100,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'Collection Book',
            style: textStyle ??
                const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF182449),
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'CREDIT & LEDGER MANAGEMENT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFC98A2D),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}