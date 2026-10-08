import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const navy = Color(0xFF0F172A);
  static const bg = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const muted = Color(0xFF64748B);
  static const hint = Color(0xFF94A3B8);
  static const danger = Color(0xFFE11D48);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);

  static Color priority(String p) {
    switch (p) {
      case 'High':
        return const Color(0xFFE11D48);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }
}

class AppTheme {
  static TextStyle heading(double size,
      {Color color = AppColors.navy, FontWeight weight = FontWeight.w800}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.3,
    );
  }

  static OutlineInputBorder _outline(Color c, [double w = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );
    final interFontFamily = GoogleFonts.inter().fontFamily;
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: interFontFamily,
        bodyColor: AppColors.navy,
        displayColor: AppColors.navy,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: AppColors.hint, fontSize: 14),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.danger),
        border: _outline(AppColors.border),
        enabledBorder: _outline(AppColors.border),
        focusedBorder: _outline(AppColors.primary, 1.5),
        errorBorder: _outline(AppColors.danger),
        focusedErrorBorder: _outline(AppColors.danger, 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}