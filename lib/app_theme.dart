import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF4F8FB);
  static const card = Colors.white;
  static const text = Color(0xFF17324D);
  static const muted = Color(0xFF6B7F92);
  static const border = Color(0xFFDCE7EF);
  static const blue = Color(0xFF247BA0);
  static const blueDark = Color(0xFF1C6483);
  static const green = Color(0xFF45A88F);
  static const orange = Color(0xFFFF9F1C);
  static const pink = Color(0xFFFF1654);
  static const softBlue = Color(0xFFEDF6FA);
  static const softOrange = Color(0xFFFFF6E8);
  static const softGreen = Color(0xFFEEF9F6);
  static const softPink = Color(0xFFFFEEF3);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.light,
    surface: AppColors.card,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Arial',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: Color(0xFF9AABB8)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFB9CBD7), width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.blue, width: 1.8),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.softBlue,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
