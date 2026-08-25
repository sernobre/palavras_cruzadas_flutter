import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF3D5AFE);
  static const Color primaryDark = Color(0xFF1A237E);
  static const Color accent = Color(0xFF00BFA5);
  static const Color background = Color(0xFFF4F6FB);
  static const Color surface = Colors.white;
  static const Color muted = Color(0xFF9AA0B4);
  static const Color block = Color(0xFF1B1F2A);
  static const Color cellBorder = Color(0xFFC9CFE0);
  static const Color activeClue = Color(0xFFE3E9FF);
  static const Color activeCell = Color(0xFFB3C0FF);
  static const Color correct = Color(0xFFC8F7DC);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 15),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
