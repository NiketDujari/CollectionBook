import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF182449); // Indigo Deep
  static const Color accent = Color(0xFFC98A2D); // Turmeric
  static const Color khadi = Color(0xFFEFE7D6);
  static const Color paper = Color(0xFFFBF8F1);
  static const Color charcoal = Color(0xFF2A2622);
  static const Color muted = Color(0xFF77705F);
  static const Color indigo = Color(0xFF2B3A67);

  // OLED Dark Palette (Matches WebView)
  static const Color oledBlack = Color(0xFF000000);
  static const Color oledSurface = Color(0xFF080808);
  static const Color oledBorder = Color(0xFF23272F);
  static const Color oledTextPrimary = Color(0xFFE9EDEF);
  static const Color oledTextSecondary = Color(0xFF8696A0);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: khadi,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      surface: paper,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: charcoal),
      bodyMedium: TextStyle(color: charcoal),
    ),
    dividerColor: const Color(0xFFD8CCB0),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: oledBlack,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF536DFE),
      secondary: Color(0xFFB08B4B),
      surface: oledBlack,
      onSurface: oledTextPrimary,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: oledTextPrimary),
      bodyMedium: TextStyle(color: oledTextPrimary),
      displayLarge: TextStyle(color: Colors.white),
    ),
    dividerColor: oledBorder,
    cardTheme: const CardThemeData(
      color: oledBlack,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
