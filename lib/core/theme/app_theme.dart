import 'package:flutter/material.dart';

class AppTheme {
  // Bảng màu ColorHunt
  static const Color myDarkNavy = Color(0xFF0D1A63);
  static const Color myMedNavy = Color(0xFF1A2CA3);
  static const Color myBrightBlue = Color(0xFF2845D6);
  static const Color myOrangeAccent = Color(0xFFF68048);
  static const Color myVeryDarkBg = Color(0xFF04081E); // Nền sâu hơn để nổi bật 4 màu trên

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: myVeryDarkBg,
      colorScheme: const ColorScheme.dark(
        primary: myBrightBlue,
        secondary: myOrangeAccent,
        surface: myDarkNavy,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: myDarkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: myDarkNavy,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: myMedNavy, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: myBrightBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: myOrangeAccent,
          side: const BorderSide(color: myOrangeAccent, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: myMedNavy.withValues(alpha: 0.3),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        hintStyle: const TextStyle(color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: myMedNavy, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: myBrightBlue, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
        displayMedium: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: myOrangeAccent), // Số siêu bự
      ),
    );
  }
}
