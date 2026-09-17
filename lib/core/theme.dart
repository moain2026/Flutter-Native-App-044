// ============================================================
// YECO - الهوية البصرية والثيم
// أخضر زمردي + كهرماني على خلفية فاتحة دافئة، خط Tajawal، Material 3
// ============================================================

import 'package:flutter/material.dart';

/// لوحة ألوان YECO
abstract final class YecoColors {
  static const primary = Color(0xFF0F9D6E); // زمردي
  static const primaryDark = Color(0xFF0B7A55);
  static const primaryLight = Color(0xFFE3F5EE);
  static const accent = Color(0xFFF5A524); // كهرماني
  static const accentLight = Color(0xFFFFF3DD);
  static const ink = Color(0xFF17212B); // نص أساسي
  static const inkSoft = Color(0xFF5B6B7A); // نص ثانوي
  static const surface = Color(0xFFF7F8F5); // خلفية
  static const card = Colors.white;
  static const line = Color(0xFFE4E8E3);
  static const danger = Color(0xFFD64545);
  static const success = Color(0xFF1E9E63);
  static const info = Color(0xFF2E6FDB);
}

ThemeData buildYecoTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: YecoColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: YecoColors.primary,
        onPrimary: Colors.white,
        secondary: YecoColors.accent,
        onSecondary: YecoColors.ink,
        surface: YecoColors.surface,
        onSurface: YecoColors.ink,
        error: YecoColors.danger,
        outline: YecoColors.line,
      );

  const font = 'Tajawal';
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: font,
    scaffoldBackgroundColor: YecoColors.surface,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: font,
      bodyColor: YecoColors.ink,
      displayColor: YecoColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: YecoColors.surface,
      foregroundColor: YecoColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: font,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: YecoColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: YecoColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: YecoColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: YecoColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: YecoColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: YecoColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: YecoColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: YecoColors.danger, width: 1.6),
      ),
      labelStyle: const TextStyle(color: YecoColors.inkSoft),
      hintStyle: const TextStyle(color: Color(0xFF9AA6B2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: font,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: YecoColors.primary,
        side: const BorderSide(color: YecoColors.primary, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: font,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: YecoColors.primary,
        textStyle: const TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: YecoColors.primary,
      side: const BorderSide(color: YecoColors.line),
      labelStyle: const TextStyle(
        fontFamily: font,
        fontWeight: FontWeight.w600,
        color: YecoColors.ink,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: YecoColors.primaryLight,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: font,
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
          color: s.contains(WidgetState.selected)
              ? YecoColors.primaryDark
              : YecoColors.inkSoft,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? YecoColors.primaryDark
              : YecoColors.inkSoft,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontFamily: font,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: YecoColors.ink,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: font,
        fontSize: 15,
        color: YecoColors.ink,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: YecoColors.ink,
      contentTextStyle: const TextStyle(fontFamily: font, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: YecoColors.line, space: 1),
    listTileTheme: const ListTileThemeData(iconColor: YecoColors.inkSoft),
    tabBarTheme: const TabBarThemeData(
      labelColor: YecoColors.primaryDark,
      unselectedLabelColor: YecoColors.inkSoft,
      indicatorColor: YecoColors.primary,
      labelStyle: TextStyle(fontFamily: font, fontWeight: FontWeight.w800),
      unselectedLabelStyle: TextStyle(fontFamily: font),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: YecoColors.primary,
    ),
  );
}
