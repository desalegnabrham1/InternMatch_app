import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0A66C2); // LinkedIn blue
  // Avoid using an overly dark blue; keep primary variants close to LinkedIn blue
  static const Color primaryDark = Color(0xFF0A66C2);
  static const Color accent = Color(0xFF5E96D6);
  static const Color background = Color(0xFFF4F2EE);
  static const Color backgroundAlt = Color(0xFFEAF3FF);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1D1D1D);
  static const Color textSecondary = Color(0xFF666666);
  static const Color divider = Color(0xFFD9E2EC);
  static const Color error = Color(0xFFCC1016);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0.8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.20),
        selectionHandleColor: primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        // Ensure labels and hints are visible on web by setting explicit styles
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        floatingLabelStyle: const TextStyle(color: primary),
      ),
      primaryTextTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: textPrimary,
            displayColor: textPrimary,
          )
          .copyWith(
            headlineMedium: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
            titleLarge: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            titleMedium: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            bodyLarge: const TextStyle(color: textPrimary, fontSize: 15),
            bodyMedium: const TextStyle(color: textSecondary, fontSize: 14),
            labelLarge: const TextStyle(
              color: primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
    );
  }

  static ThemeData get darkTheme {
    return lightTheme;
  }
}
