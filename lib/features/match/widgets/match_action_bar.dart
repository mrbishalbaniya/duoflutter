import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/duo_theme.dart';

const _amber = Color(0xFFFBBF24);

/// Skip · Rewind · Like (web `DashboardActionBar`). Profile details open from
/// the arrow on the card itself, so there is no separate info button.
class MatchActionBar extends StatelessWidget {
  const MatchActionBar({
    super.key,
    required this.disabled,
    required this.onSkip,
    required this.onLike,
    required this.onRewind,
    this.rewindDisabled = false,
    this.rewindLocked = false,
    this.rewinding = false,
    this.skipKey,
    this.rewindKey,
    this.likeKey,
  });

  final bool disabled;
  final VoidCallback onSkip;
  final VoidCallback onLike;
  final VoidCallback onRewind;

  /// Nothing swiped yet this session.
  final bool rewindDisabled;

  /// Show a lock badge: the viewer has no Rewind pass.
  final bool rewindLocked;
  final bool rewinding;
  final Key? skipKey;
  final Key? rewindKey;
  final Key? likeKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionCircle(
            key: skipKey,
            tooltip: 'Skip profile',
            icon: Icons.close_rounded,
            color: DuoColors.error,
            borderColor: DuoColors.error.withValues(alpha: 0.3),
            size: 56,
            disabled: disabled,
            onTap: () {
              HapticFeedback.lightImpact();
              onSkip();
            },
          ),
          const SizedBox(width: 18),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _ActionCircle(
                key: rewindKey,
                tooltip: rewindLocked ? 'Rewind last swipe (premium)' : 'Rewind last swipe',
                icon: Icons.replay_rounded,
                color: _amber,
                borderColor: _amber.withValues(alpha: 0.4),
                borderWidth: 1,
                size: 44,
                busy: rewinding,
                disabled: disabled || rewindDisabled || rewinding,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onRewind();
                },
              ),
              if (rewindLocked)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: _amber, shape: BoxShape.circle),
                    child: const Icon(Icons.lock_rounded, size: 12, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 18),
          _ActionCircle(
            key: likeKey,
            tooltip: 'Like profile',
            icon: Icons.favorite_rounded,
            color: const Color(0xFF10B981),
            borderColor: const Color(0xFF34D399).withValues(alpha: 0.4),
            size: 56,
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
    super.key,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onTap,
    this.size = 56,
    this.borderWidth = 2,
    this.disabled = false,
    this.busy = false,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;
  final double size;
  final double borderWidth;
  final bool disabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: disabled && !busy ? 0.45 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: disabled ? null : onTap,
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: busy
                  ? Padding(
                      padding: EdgeInsets.all(size * 0.28),
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    )
                  : Icon(icon, color: color, size: size * 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
