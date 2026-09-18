// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // ── Light mode ──────────────────────────────────────────────
  static const Color background = Color(0xFFF4F1EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFEAE5DC);
  static const Color primary = Color(0xFF5B7FFF);
  static const Color primaryDark = Color(0xFF3D5FE0);
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // ── Dark mode ───────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F0F14);
  static const Color darkSurface = Color(0xFF1A1A24);
  static const Color darkSurfaceAlt = Color(0xFF222230);
  static const Color darkDivider = Color(0xFF2A2A3A);
  static const Color darkTextPrimary = Color(0xFFF0F0F8);
  static const Color darkTextSecondary = Color(0xFF9494B0);
  static const Color darkTextMuted = Color(0xFF5A5A72);

  // ── Category icon backgrounds ────────────────────────────────
  static const Map<String, Color> catBg = {
    'home': Color(0xFFE8F0FF),
    'restaurant': Color(0xFFFFF3E0),
    'directions_car': Color(0xFFE8F5E9),
    'shopping_bag': Color(0xFFFCE4EC),
    'favorite': Color(0xFFFFEBEE),
    'sports_esports': Color(0xFFEDE7F6),
    'school': Color(0xFFE3F2FD),
    'bolt': Color(0xFFF5F5F5),
    'account_balance_wallet': Color(0xFFE8F5E9),
    'more_horiz': Color(0xFFF5F5F5),
  };
  static const Map<String, Color> catBgDark = {
    'home': Color(0xFF1A2040),
    'restaurant': Color(0xFF2A1F0A),
    'directions_car': Color(0xFF0D2010),
    'shopping_bag': Color(0xFF2A0D18),
    'favorite': Color(0xFF2A0D0D),
    'sports_esports': Color(0xFF1E1030),
    'school': Color(0xFF0D1830),
    'bolt': Color(0xFF1E1E28),
    'account_balance_wallet': Color(0xFF0D2010),
    'more_horiz': Color(0xFF1E1E28),
  };
  static const Map<String, Color> catFg = {
    'home': Color(0xFF5B7FFF),
    'restaurant': Color(0xFFFF9800),
    'directions_car': Color(0xFF4CAF50),
    'shopping_bag': Color(0xFFE91E63),
    'favorite': Color(0xFFF44336),
    'sports_esports': Color(0xFF9C27B0),
    'school': Color(0xFF2196F3),
    'bolt': Color(0xFF9E9E9E),
    'account_balance_wallet': Color(0xFF4CAF50),
    'more_horiz': Color(0xFF757575),
  };

  static const List<Color> chart = [
    Color(0xFF5B7FFF),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF9CA3AF),
  ];
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.income,
          surface: AppColors.surface,
          error: AppColors.expense,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5),
          displayMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3),
          headlineMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          titleLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          titleMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          bodyLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary),
          bodyMedium: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary),
          labelSmall: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.expense,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: const BorderSide(color: AppColors.expense),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.expense)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.expense, width: 1.5)),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme:
            const DividerThemeData(color: AppColors.divider, thickness: 1),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.income,
          surface: AppColors.darkSurface,
          error: AppColors.expense,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.darkTextPrimary,
              letterSpacing: -0.5),
          displayMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextPrimary,
              letterSpacing: -0.3),
          headlineMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextPrimary),
          titleLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextPrimary),
          titleMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextPrimary),
          bodyLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.darkTextPrimary),
          bodyMedium: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.darkTextSecondary),
          labelSmall: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.darkTextMuted),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextPrimary),
          iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.darkDivider),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.expense,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: const BorderSide(color: AppColors.expense),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkDivider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkDivider)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.expense)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.expense, width: 1.5)),
          labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
          hintStyle: const TextStyle(color: AppColors.darkTextMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme:
            const DividerThemeData(color: AppColors.darkDivider, thickness: 1),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkSurfaceAlt,
          contentTextStyle: const TextStyle(color: AppColors.darkTextPrimary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.darkSurface,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.darkSurface,
        ),
      );
}

// ── Theme-aware color helpers ─────────────────────────────────
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor => isDark ? AppColors.darkBackground : AppColors.background;
  Color get surfColor => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get surfAlt => isDark ? AppColors.darkSurfaceAlt : AppColors.background;
  Color get divColor => isDark ? AppColors.darkDivider : AppColors.divider;
  Color get txtPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get txtSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get txtMuted => isDark ? AppColors.darkTextMuted : AppColors.textMuted;

  Color catBgColor(String icon) => isDark
      ? (AppColors.catBgDark[icon] ?? const Color(0xFF1E1E28))
      : (AppColors.catBg[icon] ?? const Color(0xFFF5F5F5));
}
