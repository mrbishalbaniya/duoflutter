import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileEditFab extends StatelessWidget {
  const ProfileEditFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Edit profile',
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        elevation: 4,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        icon: const Icon(Icons.edit_rounded),
        label: const Text(
          'Edit',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 300.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }
}
