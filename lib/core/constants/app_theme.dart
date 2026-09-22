import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette (Deep forest green)
  static const Color primary = Color(0xFF0F3E34);
  static const Color primaryDark = Color(0xFF0B2E27);
  static const Color primaryLight = Color(0xFF1B5548);

  // Background & surfaces
  static const Color background = Color(0xFFF1F6F3);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE4ECE7);

  // Accents
  static const Color orange = Color(0xFFEE7D32);
  static const Color orangeLight = Color(0xFFFFF0E6);
  static const Color orangeText = Color(0xFFC75D19);

  static const Color mint = Color(0xFFD3F4E2);
  static const Color mintDark = Color(0xFF0F5B3E);
  static const Color mintBg = Color(0xFFEAF8F0);

  static const Color peachBg = Color(0xFFFDF0E7);
  static const Color peachText = Color(0xFFB3561A);

  static const Color blueGray = Color(0xFFE6EFF2);
  static const Color blueGrayText = Color(0xFF335C67);

  // Text colors
  static const Color textPrimary = Color(0xFF14241F);
  static const Color textSecondary = Color(0xFF6B7E76);
  static const Color textMuted = Color(0xFF8C9E97);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
