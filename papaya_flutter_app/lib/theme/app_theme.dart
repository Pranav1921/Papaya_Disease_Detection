import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Agriculture & Indian Tricolor Color Palette
  static const Color forestGreen = Color(0xFF138808); // Tricolor Green
  static const Color emeraldGreen = Color(0xFF0F6E05); // Deep Green
  static const Color mintGreen = Color(0xFF4CAF50);
  static const Color lightSage = Color(0xFFF4F9F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color leafGold = Color(0xFFFF9933); // Tricolor Saffron
  static const Color amberWarning = Color(0xFFFF9933); // Tricolor Saffron
  static const Color redAlert = Color(0xFFD32F2F);
  static const Color darkMoss = Color(0xFF0A183C); // Tricolor Navy Blue
  static const Color softGrey = Color(0xFFE0E0E0);
  static const Color textDark = Color(0xFF1C2826);
  static const Color textMuted = Color(0xFF5A6B65);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [forestGreen, emeraldGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF381B04), Color(0xFF0A183C), Color(0xFF042D08)], // Dark Saffron -> Dark Navy -> Dark Green
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGlassGradient = LinearGradient(
    colors: [Color(0xEEFFFFFF), Color(0xDDEDF7F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFE67E22), Color(0xFFFF9933)], // Saffron warning tones
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: forestGreen,
        primary: forestGreen,
        secondary: emeraldGreen,
        tertiary: leafGold,
        background: lightSage,
        surface: surfaceWhite,
        error: redAlert,
      ),
      scaffoldBackgroundColor: lightSage,
      textTheme: GoogleFonts.notoSansKannadaTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: textDark,
        displayColor: forestGreen,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansKannada(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.notoSansKannada(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 3,
        shadowColor: forestGreen.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
