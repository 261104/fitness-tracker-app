import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Purple, lavender, white, and green palette.
class AppColors {
  AppColors._();

  static const Color purple = Color(0xFF5B21B6);
  static const Color purpleDeep = Color(0xFF4C1D95);
  static const Color lavender = Color(0xFFE9D5FF);
  static const Color lavenderSoft = Color(0xFFF5F3FF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFDCFCE7);
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        primary: AppColors.purple,
        secondary: AppColors.green,
        surface: AppColors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.lavenderSoft,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.purple,
        foregroundColor: AppColors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.lavender,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            fontSize: 12,
            color: AppColors.textDark,
          ),
        ),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
    );
  }
}
