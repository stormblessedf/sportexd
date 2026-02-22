import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Delegate all colors to AppColors (single source of truth)
  static const Color primary = AppColors.primary;
  static const Color primaryHover = AppColors.primaryHover;
  static const Color backgroundLight = AppColors.backgroundLight;
  static const Color surfaceLight = AppColors.surfaceLight;
  static const Color textDark = AppColors.textDark;
  static const Color textMuted = AppColors.textMuted;
  static const Color textLight = AppColors.textLight;
  static const Color borderLight = AppColors.borderLight;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        surface: surfaceLight,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.lexendTextTheme(
        ThemeData.light().textTheme.copyWith(
          headlineLarge: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
          headlineSmall: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(color: textDark, fontWeight: FontWeight.w600),
          titleMedium: const TextStyle(color: textDark, fontWeight: FontWeight.w600),
          titleSmall: const TextStyle(color: textDark, fontWeight: FontWeight.w500),
          bodyLarge: const TextStyle(color: textMuted),
          bodyMedium: const TextStyle(color: textMuted),
          bodySmall: const TextStyle(color: textLight),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: backgroundLight,
        foregroundColor: textDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        hintStyle: const TextStyle(color: textLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textDark,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primary,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: GoogleFonts.lexend(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: borderLight,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.2),
      ),
    );
  }

  // Keep dark theme for future use but make it match the new design
  static ThemeData get darkTheme {
    final light = lightTheme;
    return light.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: light.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: const Color(0xFF1E293B),
        onSurface: Colors.white,
      ),
      cardTheme: light.cardTheme.copyWith(
        color: const Color(0xFF1E293B),
      ),
      appBarTheme: light.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: light.bottomNavigationBarTheme.copyWith(
        backgroundColor: const Color(0xFF1E293B),
        unselectedItemColor: const Color(0xFF94A3B8),
      ),
      dividerTheme: light.dividerTheme.copyWith(
        color: const Color(0xFF334155),
      ),
    );
  }
}
