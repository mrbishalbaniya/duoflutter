import 'package:flutter/material.dart';

import 'duo_theme.dart';

abstract final class DuoGradients {
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [DuoColors.primary, DuoColors.love, DuoColors.accent],
  );

  static const brandBr = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [DuoColors.primary, DuoColors.primaryContainer],
  );

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x4DE84A7A),
      Color(0x4D8B5CF6),
      Color(0x4DD4A574),
    ],
  );

  static const profileHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x4DE84A7A),
      Color(0x8017181A),
      Color(0x4DD4A574),
    ],
  );
}
