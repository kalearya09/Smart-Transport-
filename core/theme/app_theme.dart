import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary    = Color(0xFF2563EB);
  static const primaryLt  = Color(0xFF3B82F6);
  static const accent     = Color(0xFF06B6D4);
  static const success    = Color(0xFF10B981);
  static const warning    = Color(0xFFF59E0B);
  static const error      = Color(0xFFEF4444);
  static const sos        = Color(0xFFDC2626);

  // Light
  static const lBg        = Color(0xFFF8FAFC);
  static const lCard      = Color(0xFFFFFFFF);
  static const lSurface   = Color(0xFFF1F5F9);
  static const lBorder    = Color(0xFFE2E8F0);
  static const lText      = Color(0xFF0F172A);
  static const lSubtext   = Color(0xFF64748B);

  // Dark
  static const dBg        = Color(0xFF0B1120);
  static const dCard      = Color(0xFF131C2E);
  static const dSurface   = Color(0xFF1E2A3A);
  static const dBorder    = Color(0xFF2D3B50);
  static const dText      = Color(0xFFF1F5F9);
  static const dSubtext   = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final bg      = isDark ? AppColors.dBg      : AppColors.lBg;
    final card    = isDark ? AppColors.dCard    : AppColors.lCard;
    final surface = isDark ? AppColors.dSurface : AppColors.lSurface;
    final border  = isDark ? AppColors.dBorder  : AppColors.lBorder;
    final text    = isDark ? AppColors.dText    : AppColors.lText;
    final subtext = isDark ? AppColors.dSubtext : AppColors.lSubtext;
    final primary = isDark ? AppColors.primaryLt : AppColors.primary;

    final base = GoogleFonts.poppinsTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: b,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        background: bg,
        onBackground: text,
        surface: card,
        onSurface: text,
      ),
      textTheme: base.copyWith(
        displayLarge:  base.displayLarge?.copyWith(color: text, fontWeight: FontWeight.w700, fontSize: 32),
        displayMedium: base.displayMedium?.copyWith(color: text, fontWeight: FontWeight.w700, fontSize: 24),
        headlineMedium:base.headlineMedium?.copyWith(color: text, fontWeight: FontWeight.w600, fontSize: 20),
        titleLarge:    base.titleLarge?.copyWith(color: text, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium:   base.titleMedium?.copyWith(color: text, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge:     base.bodyLarge?.copyWith(color: text, fontSize: 14),
        bodyMedium:    base.bodyMedium?.copyWith(color: subtext, fontSize: 12),
        labelLarge:    base.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: GoogleFonts.poppins(
            color: text, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.poppins(color: subtext, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: subtext, fontSize: 14),
      ),
    );
  }
}