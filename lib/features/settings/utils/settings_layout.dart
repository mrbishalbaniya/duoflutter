import 'package:flutter/material.dart';

/// Responsive layout tokens for the Settings feature.
abstract final class SettingsLayout {
  static const tabletBreakpoint = 840.0;
  static const desktopBreakpoint = 1200.0;
  static const maxContentWidth = 1152.0;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return 48;
    if (width >= tabletBreakpoint) return 32;
    if (width >= 600) return 24;
    return 16;
  }

  static double bottomPadding(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + 120;
  }

  static double sectionSpacing(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletBreakpoint ? 24 : 20;
  }

  static double columnGap(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint ? 40 : 32;
  }

  static bool useTwoColumns(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletBreakpoint;
  }

  static int staggerDelayMs(int index) => 40 + (index * 35);
}
