import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../domain/verification_domain.dart';

/// Four clear stages (web VerificationFlow): Start · Face check · Selfie · Result.
class VerificationProgressBar extends StatelessWidget {
  const VerificationProgressBar({super.key, required this.step});

  final VerificationFlowStep step;

  static const _stages = ['Start', 'Face check', 'Selfie', 'Result'];

  int get _stageIndex => switch (step) {
        VerificationFlowStep.liveness || VerificationFlowStep.crossDevice => 1,
        VerificationFlowStep.selfie => 2,
        VerificationFlowStep.processing || VerificationFlowStep.result => 3,
        VerificationFlowStep.instructions => 0,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duo = context.duo;
    final current = _stageIndex;

    return Row(
      children: [
        for (var i = 0; i < _stages.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Builder(builder: (context) {
              final done = i < current || (i == 3 && step == VerificationFlowStep.result);
              final active = i == current && !done;
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: done ? duo.brandGradient : null,
                      color: done
                          ? null
                          : active
                              ? scheme.primary.withValues(alpha: 0.5)
                              : scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stages[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: active || done
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ],
    );
  }
}
