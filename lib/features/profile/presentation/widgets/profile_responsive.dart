import 'package:flutter/material.dart';

/// Breakpoints and spacing helpers for profile layouts.
class ProfileResponsive {
  const ProfileResponsive._();

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 840;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 840) return 32;
    if (width >= 600) return 28;
    return 20;
  }

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 1080;
    if (width >= 840) return 920;
    return width;
  }

  static double heroHeight(BuildContext context) {
    if (isWide(context)) return 280;
    if (isTablet(context)) return 220;
    return isLandscape(context) ? 160 : 200;
  }

  static double avatarRadius(BuildContext context) {
    if (isWide(context)) return 64;
    if (isTablet(context)) return 58;
    return 52;
  }

  static int gridColumns(BuildContext context) {
    if (isWide(context)) return 2;
    return 1;
  }
}
