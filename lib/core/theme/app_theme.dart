import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // === LIGHT MODE ("Sunlight") ===
  // Warm, sun-drenched pool/beach daytime look: cream/sand backgrounds,
  // bright turquoise water as the primary accent, gold sunlight highlights.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryTeal,
        brightness: Brightness.light,
        primary: AppColors.primaryTeal,
        secondary: AppColors.sunGold,
        tertiary: AppColors.coral,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.lightGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightGray,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.deepNavy),
        titleTextStyle: TextStyle(
          color: AppColors.deepNavy,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.sunGold,
        foregroundColor: AppColors.deepNavy,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: AppColors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: Color(0xFFB8A88F),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sand,
        selectedColor: AppColors.primaryTeal.withOpacity(0.2),
        labelStyle: const TextStyle(color: AppColors.deepNavy),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // === DARK MODE ("Moonlight") ===
  // Deep-ocean-at-night look: near-black navy sky, moonlit water surface,
  // glowing cyan reflections, silvery highlights.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.moonlightAccent,
        brightness: Brightness.dark,
        primary: AppColors.moonlightAccent,
        secondary: AppColors.moonlightSilver,
        tertiary: AppColors.moonlightGold,
        surface: AppColors.moonlightSurface,
      ),
      scaffoldBackgroundColor: AppColors.moonlightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.moonlightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.moonlightText),
        titleTextStyle: TextStyle(
          color: AppColors.moonlightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.moonlightAccent,
        foregroundColor: AppColors.moonlightBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.moonlightAccent,
          foregroundColor: AppColors.moonlightBackground,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.moonlightSurface,
        selectedItemColor: AppColors.moonlightAccent,
        unselectedItemColor: Color(0xFF64809C),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.moonlightSurfaceAlt,
        selectedColor: AppColors.moonlightAccent.withOpacity(0.25),
        labelStyle: const TextStyle(color: AppColors.moonlightText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.moonlightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.moonlightText),
        bodyMedium: TextStyle(color: AppColors.moonlightText),
      ),
    );
  }
}
