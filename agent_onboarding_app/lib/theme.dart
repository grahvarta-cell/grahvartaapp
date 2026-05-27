import 'package:flutter/material.dart';

class AppColors {
  static const background  = Color(0xFF0D0D0D);
  static const surface     = Color(0xFF1A1A1A);
  static const surfaceLight= Color(0xFF222222);
  static const card        = Color(0xFF1E1E1E);
  static const primary     = Color(0xFFE8762A);   // orange
  static const primaryLight= Color(0xFFF08C3E);
  static const gold        = Color(0xFFD4A843);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary=Color(0xFFAAAAAA);
  static const textMuted   = Color(0xFF666666);
  static const border      = Color(0xFF2A2A2A);
  static const success     = Color(0xFF43A047);
  static const error       = Color(0xFFE53935);
  // legacy aliases kept for chip/slider
  static const chipSelected   = primary;
  static const chipUnselected = surface;
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.gold,
    surface: AppColors.surface,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSurface: AppColors.textPrimary,
  ),
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceLight,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    hintStyle: const TextStyle(color: AppColors.textMuted),
    prefixIconColor: AppColors.textMuted,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  cardTheme: const CardThemeData(
    color: AppColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.border),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted),
    trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary.withValues(alpha: 0.4) : AppColors.surfaceLight),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: AppColors.primary,
    thumbColor: AppColors.primary,
    inactiveTrackColor: AppColors.surfaceLight,
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: AppColors.card),
);
