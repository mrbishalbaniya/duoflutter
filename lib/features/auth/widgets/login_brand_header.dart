import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/duo_gradients.dart';

/// Compact brand block for the login screen: small logo + "Duo" wordmark.
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset('assets/brand/duo_logo.png', width: 44, height: 44, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => DuoGradients.brand.createShader(bounds),
          child: const Text(
            'Duo',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: -0.08, end: 0, duration: 450.ms, curve: Curves.easeOutCubic);
  }
}
