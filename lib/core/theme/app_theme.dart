import 'package:flutter/material.dart';

class AppTheme {
  // Palette (Target: 50-60s, Warm & Comfortable)
  // Warm Rice Paper - darker/warmer than current for eye comfort
  static const Color background = Color(0xFFFFFFFF);
  // Clean White for cards/surfaces
  static const Color surface = Color(0xFFFFFFFF);
  // Soft Beige for inputs/secondary surfaces
  static const Color surfaceAlt = Color(0xFFF0EBE5);
  // Soft Black - High contrast but not harsh
  static const Color textPrimary = Color(0xFF2D2C2A);
  // Warm Gray
  static const Color textSecondary = Color(0xFF5D5A56);
  // Warm Border
  static const Color border = Color(0xFFE0DCD5);

  // Warm Indigo - Trustworthy & Calm (Replaces aggressive Coral)
  static const Color accent = Color(0xFF212121);
  // Pale Indigo for backgrounds/highlights
  static const Color accentSoft = Color(0xFFF5F5F5);

  static const double radius12 = 12;
  static const double radius16 = 16;
  static const double radius24 = 24; // Increased from 20 for softer look

  static const _shadow = [
    BoxShadow(
      color: Color(0x14000000), // Slightly more transparent
      blurRadius: 20, // Softer blur
      offset: Offset(0, 8),
    ),
  ];

  static ColorScheme get _scheme {
    return ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      surface: surface,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      outline: border,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _scheme,
      scaffoldBackgroundColor: background,

      // Typography - Adjusted for 50-60s readability
      fontFamily: 'Pretendard',
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800, // Increased weight for clarity
          color: textPrimary,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.35,
        ),
        titleMedium: TextStyle(
          fontSize: 17, // Increased from 16
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          height: 1.65,
          color: textPrimary,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontSize: 16, // Increased from 15
          height: 1.6,
          color: textPrimary,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontSize: 15, // Increased from 14
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20, // Increased from 18
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      dividerTheme: const DividerThemeData(color: border, thickness: 1),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius24),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
        ),
        elevation: 4,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt, // Changed to surfaceAlt
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        hintStyle:
            const TextStyle(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 16),
        labelStyle:
            const TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius16),
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent, // Use accent color
          side: const BorderSide(color: border),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius16),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
        ),
      ),
    );
  }

  static BoxDecoration cardDecoration({bool elevated = false}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius24),
      border: Border.all(color: border),
      boxShadow: elevated ? _shadow : const [],
    );
  }
}
