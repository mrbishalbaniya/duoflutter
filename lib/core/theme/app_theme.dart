import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

/// Entry point for Duo adaptive Material 3 themes.
abstract final class AppTheme {
  static ThemeData light() => buildLightTheme();
  static ThemeData dark() => buildDarkTheme();
}

/// Backward-compatible facade.
abstract final class DuoTheme {
  static ThemeData light() => AppTheme.light();
  static ThemeData dark() => AppTheme.dark();
}
