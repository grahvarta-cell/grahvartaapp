import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Dark theme colors
class AppColors {
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF222222);
  static const Color card = Color(0xFF1E1E1E);
  static const Color orange = Color(0xFFE8762A);
  static const Color orangeLight = Color(0xFFF08C3E);
  static const Color orangeDark = Color(0xFFB85C1A);
  static const Color gold = Color(0xFFD4A843);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF666666);
  static const Color border = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF1F1F1F);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
}

// Light theme Flutter color palette
class LightColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFEEF4FF);
  static const Color surfaceLight = Color(0xFFE5EEFF);
  static const Color card = Color(0xFFF0F6FF);
  static const Color flutterNavy = Color(0xFF042B59);
  static const Color flutterBlue = Color(0xFF0553B1);
  static const Color flutterSky = Color(0xFF027DFD);
  static const Color red = Color(0xFFF25D50);
  static const Color yellow = Color(0xFFFFF275);
  static const Color purple = Color(0xFF6200EE);
  static const Color green = Color(0xFF1CDAC5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF042B59);
  static const Color textSecondary = Color(0xFF0553B1);
  static const Color textMuted = Color(0xFF666666);
  static const Color border = Color(0xFFC8D8F0);
  static const Color divider = Color(0xFFD5E5F5);
  static const Color error = Color(0xFFF25D50);
  static const Color success = Color(0xFF1CDAC5);
  static const Color orange = Color(0xFFE8762A);
}

/// Context extension — use `context.clr.bg`, `context.clr.txtPrimary`, etc.
extension ThemeColors on BuildContext {
  AppColorSet get clr => Theme.of(this).brightness == Brightness.dark ? const AppColorSet._dark() : const AppColorSet._light();
}

class AppColorSet {
  final bool _dark;
  const AppColorSet._dark() : _dark = true;
  const AppColorSet._light() : _dark = false;

  Color get bg          => _dark ? AppColors.background   : LightColors.background;
  Color get surface     => _dark ? AppColors.surface      : LightColors.surface;
  Color get surfaceLight=> _dark ? AppColors.surfaceLight : LightColors.surfaceLight;
  Color get card        => _dark ? AppColors.card         : LightColors.card;
  Color get txtPrimary  => _dark ? AppColors.textPrimary  : LightColors.textPrimary;
  Color get txtSecondary=> _dark ? AppColors.textSecondary: LightColors.textSecondary;
  Color get txtMuted    => _dark ? AppColors.textMuted    : LightColors.textMuted;
  Color get border      => _dark ? AppColors.border       : LightColors.border;
  Color get divider     => _dark ? AppColors.divider      : LightColors.divider;
  Color get accent      => _dark ? AppColors.orange       : LightColors.flutterSky;
  Color get accentAlt   => _dark ? AppColors.gold         : LightColors.flutterBlue;
  Color get error       => _dark ? AppColors.error        : LightColors.error;
  Color get success     => _dark ? AppColors.success      : LightColors.success;
  Color get navy        => _dark ? AppColors.orange       : LightColors.flutterNavy;
  // AppBar background is always accent-colored in both themes, so text/icons on it are always white
  Color get onAppBar    => Colors.white;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.orange,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: const BorderSide(color: AppColors.orange),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: LightColors.background,
      colorScheme: const ColorScheme.light(
        primary: LightColors.flutterSky,
        secondary: LightColors.flutterBlue,
        surface: LightColors.surface,
        error: LightColors.error,
        onPrimary: LightColors.white,
        onSecondary: LightColors.white,
        onSurface: LightColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: LightColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: LightColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: LightColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(color: LightColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: LightColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: LightColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: LightColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: LightColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: LightColors.textSecondary, fontSize: 16),
          bodyMedium: TextStyle(color: LightColors.textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: LightColors.textMuted, fontSize: 12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LightColors.flutterSky,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: LightColors.white),
        titleTextStyle: TextStyle(
          color: LightColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: LightColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LightColors.flutterSky,
          foregroundColor: LightColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LightColors.flutterSky,
          side: const BorderSide(color: LightColors.flutterSky),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LightColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LightColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LightColors.flutterSky, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LightColors.error),
        ),
        labelStyle: const TextStyle(color: LightColors.textSecondary),
        hintStyle: const TextStyle(color: LightColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: LightColors.divider),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: LightColors.card,
        selectedItemColor: LightColors.flutterSky,
        unselectedItemColor: LightColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
