import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/duo_theme.dart';

/// Animated three-dot typing indicator (header + in-thread).
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({
    super.key,
    this.compact = false,
    this.showLabel = true,
    this.avatarUrl,
  });

  final bool compact;
  final bool showLabel;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (avatarUrl != null && !compact) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.surfaceContainerHighest,
            backgroundImage: NetworkImage(avatarUrl!),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 10,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabel) ...[
                Text(
                  'Typing',
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: DuoColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const _TypingDots(),
            ],
          ),
        ),
      ],
    );
  }
}

class ChatTypingLabel extends StatelessWidget {
  const ChatTypingLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Typing',
          style: TextStyle(
            color: DuoColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        const _TypingDots(dotSize: 4),
      ],
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({this.dotSize = 5});

  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final color = DuoColors.primary.withValues(alpha: 0.85);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 300.ms, delay: (120 * index).ms)
              .then()
              .fadeOut(duration: 300.ms)
              .then(delay: 200.ms),
        );
      }),
    );
  }
}
