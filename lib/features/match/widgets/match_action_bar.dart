import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/duo_theme.dart';

class MatchActionBar extends StatelessWidget {
  const MatchActionBar({
    super.key,
    required this.disabled,
    required this.onSkip,
    required this.onInfo,
    required this.onLike,
  });

  final bool disabled;
  final VoidCallback onSkip;
  final VoidCallback onInfo;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionCircle(
            icon: Icons.close_rounded,
            color: DuoColors.error,
            borderColor: DuoColors.error.withValues(alpha: 0.35),
            size: 56,
            disabled: disabled,
            onTap: () {
              HapticFeedback.lightImpact();
              onSkip();
            },
          ),
          const SizedBox(width: 20),
          _ActionCircle(
            icon: Icons.info_outline_rounded,
            color: DuoColors.primary,
            borderColor: DuoColors.primary.withValues(alpha: 0.25),
            size: 48,
            disabled: disabled,
            onTap: () {
              HapticFeedback.selectionClick();
              onInfo();
            },
          ),
          const SizedBox(width: 20),
          _ActionCircle(
            icon: Icons.favorite_rounded,
            color: Colors.green.shade500,
            borderColor: Colors.green.shade400.withValues(alpha: 0.45),
            size: 56,
            filled: true,
            disabled: disabled,
            onTap: () {
              HapticFeedback.mediumImpact();
              onLike();
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onTap,
    this.size = 56,
    this.filled = false,
    this.disabled = false,
  });

  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;
  final double size;
  final bool filled;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: disabled ? null : onTap,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Theme.of(context).colorScheme.surface,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: filled ? Colors.white : color,
            size: size * 0.42,
          ),
        ),
      ),
    );
  }
}
