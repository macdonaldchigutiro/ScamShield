import 'package:flutter/material.dart';

import '../../theme.dart';

/// Builds the top-level Material theme used across ScamShield.
///
/// Feature-specific styling still lives close to each feature. This class only
/// owns global visual rules such as brightness, colours and Material version.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Palette.bg,
      colorScheme: const ColorScheme.dark(
        primary: Palette.cyan,
        secondary: Palette.violet,
        surface: Color(0xFF0A1226),
      ),
      useMaterial3: true,
    );
  }
}
