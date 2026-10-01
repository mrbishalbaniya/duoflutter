import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../widgets/duo_ui.dart';
import '../verification_controller.dart';
import 'verification_error_banner.dart';

/// Start screen, matching web VerificationFlow "instructions".
class VerificationInstructionsStep extends StatelessWidget {
  const VerificationInstructionsStep({
    super.key,
    required this.state,
    required this.onStartDevice,
    required this.onStartCrossDevice,
  });

  final VerificationState state;
  final VoidCallback onStartDevice;
  final VoidCallback onStartCrossDevice;

  static const _tips = [
    (Icons.light_mode_outlined, 'Find good light and face the camera'),
    (Icons.gesture_rounded, 'Follow 3 quick moves, like a smile or a head turn'),
    (Icons.person_outline_rounded, 'Keep only your face in the frame'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duo = context.duo;

    if (state.submitting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text('Getting things ready…', style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: duo.brandGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: scheme.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Get your verified badge',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          "A quick face check shows people you're the person in your photos.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < _tips.length; i++) ...[
                if (i > 0) Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.15)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Icon(_tips[i].$1, size: 22, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_tips[i].$2, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Takes under a minute. Photos are captured automatically.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          VerificationErrorBanner(message: state.error!),
        ],
        const SizedBox(height: 24),
        DuoGradientButton(label: 'Start verification', onPressed: onStartDevice),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onStartCrossDevice,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            shape: const StadiumBorder(),
            foregroundColor: scheme.primary,
          ),
          icon: const Icon(Icons.smartphone_rounded, size: 20),
          label: const Text('Use another device instead', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ].animate(interval: 40.ms).fadeIn(duration: 260.ms).slideY(begin: 0.04, end: 0),
    );
  }
}
