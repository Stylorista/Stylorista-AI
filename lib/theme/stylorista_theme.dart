import 'package:flutter/material.dart';

abstract final class StyloristaColors {
  static const ink = Color(0xFF1D1A1B);
  static const cream = Color(0xFFF8F4ED);
  static const paper = Color(0xFFFFFCF7);
  static const plum = Color(0xFF7B315D);
  static const berry = Color(0xFFB9547A);
  static const moss = Color(0xFF5F7150);
  static const gold = Color(0xFFC5964C);
}

ThemeData buildStyloristaTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: StyloristaColors.plum,
    brightness: Brightness.light,
    surface: StyloristaColors.paper,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme.copyWith(
      primary: StyloristaColors.plum,
      secondary: StyloristaColors.moss,
      tertiary: StyloristaColors.gold,
      surface: StyloristaColors.paper,
      onSurface: StyloristaColors.ink,
    ),
    scaffoldBackgroundColor: StyloristaColors.cream,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 42,
        height: 1.05,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        color: StyloristaColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: StyloristaColors.paper,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: StyloristaColors.ink.withValues(alpha: 0.08)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: StyloristaColors.ink.withValues(alpha: 0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: StyloristaColors.plum, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
