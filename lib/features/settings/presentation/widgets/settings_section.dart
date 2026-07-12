import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.child,
    this.animationIndex = 0,
    this.visible = true,
  });

  final String title;
  final Widget child;
  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.22)),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 260.ms, delay: Duration(milliseconds: animationIndex * 35))
          .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
    );
  }
}
