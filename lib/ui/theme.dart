import 'package:flutter/material.dart';

/// Barvy a styl aplikace. Tmavý režim je výchozí.
abstract final class AppColors {
  static const accent = Color(0xFFC6F36B);
  static const darkBackground = Color(0xFF0F1115);
  static const darkSurface = Color(0xFF181B21);
  static const lightBackground = Color(0xFFF6F7F4);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: brightness,
      ).copyWith(
        primary: dark ? AppColors.accent : const Color(0xFF3F5F00),
        onPrimary: dark ? AppColors.darkBackground : Colors.white,
        surface: dark ? AppColors.darkBackground : AppColors.lightBackground,
        surfaceContainer: dark ? AppColors.darkSurface : Colors.white,
      );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
