import 'package:flutter/material.dart';

import '../../../core/theme/duo_theme.dart';

class EsewaLogo extends StatelessWidget {
  const EsewaLogo({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 8,
      height: size + 4,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DuoColors.esewaGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: DuoColors.esewaGreen.withValues(alpha: 0.45)),
      ),
      child: Text(
        'e',
        style: TextStyle(
          color: DuoColors.esewaGreen,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.75,
        ),
      ),
    );
  }
}
