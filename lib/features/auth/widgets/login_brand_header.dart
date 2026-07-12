import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Brand block from DuoFrontend `/login` header.
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/logo.png',
            width: 112,
            height: 112,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Find your digital heirloom',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: -0.08, end: 0, duration: 450.ms, curve: Curves.easeOutCubic);
  }
}
