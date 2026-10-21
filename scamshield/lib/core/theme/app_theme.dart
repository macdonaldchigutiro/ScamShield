import 'package:flutter/material.dart';

import '../../theme.dart';

/// Top-level Material theme for ScamShield.
///
/// The global theme prioritises readability and familiar Material behaviour.
/// Feature screens can still add local emphasis for warnings and investigations.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: Palette.bg,
      colorScheme: const ColorScheme.dark(
        primary: Palette.cyan,
        secondary: Palette.green,
        error: Palette.red,
        surface: Palette.surface,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Palette.text,
        displayColor: Palette.text,
      ),
      dividerColor: Palette.line,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Palette.surface,
        indicatorColor: Palette.cyan.withOpacity(.16),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Palette.surface,
        indicatorColor: Color(0x294DA3FF),
        selectedLabelTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: Palette.text,
        ),
        unselectedLabelTextStyle: TextStyle(color: Palette.dim),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.surfaceHi,
        hintStyle: const TextStyle(color: Palette.dim),
        labelStyle: const TextStyle(color: Palette.dim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Palette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Palette.line),
        ),
      ),
    );
  }
}
