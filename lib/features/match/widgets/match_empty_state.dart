import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/theme_extensions.dart';

const _amber = Color(0xFFFBBF24);

/// Web match empty state: "No one matches your filters" when filters could be
/// loosened, otherwise "You're all caught up".
class MatchEmptyState extends StatelessWidget {
  const MatchEmptyState({
    super.key,
    required this.filtered,
    required this.canWiden,
    required this.activeFilterCount,
    required this.onWiden,
    required this.onRefresh,
    required this.onAdjustFilters,
    this.widening = false,
    this.refreshing = false,
    this.showRewind = false,
    this.rewindLocked = false,
    this.rewinding = false,
    this.onRewind,
  });

  final bool filtered;
  final bool canWiden;
  final int activeFilterCount;
  final VoidCallback onWiden;
  final VoidCallback onRefresh;
  final VoidCallback onAdjustFilters;
  final bool widening;
  final bool refreshing;
  final bool showRewind;
  final bool rewindLocked;
  final bool rewinding;
  final VoidCallback? onRewind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duo = context.duo;
    final text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24)],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -96,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 224,
                      height: 224,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [scheme.primary.withValues(alpha: 0.22), scheme.primary.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StackedIcon(filtered: filtered)
                          .animate()
                          .fadeIn(duration: 280.ms)
                          .scale(begin: const Offset(0.9, 0.9)),
                      const SizedBox(height: 32),
                      Text(
                        filtered ? 'No one matches your filters' : "You're all caught up",
                        textAlign: TextAlign.center,
                        style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        filtered
                            ? 'Loosen a filter or two to see more people. New members join Duo every day.'
                            : "You've seen everyone nearby for now. Check back soon for new faces.",
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
                      ),
                      if (filtered) ...[
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final (icon, label) in const [
                              (Icons.cake_outlined, 'Wider age range'),
                              (Icons.near_me_outlined, 'Bigger distance'),
                              (Icons.checklist_rounded, 'Fewer requirements'),
                            ])
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 16, color: scheme.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      label,
                                      style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                      _GradientButton(
                        gradient: duo.brandGradient,
                        foreground: scheme.onPrimary,
                        icon: canWiden ? Icons.travel_explore_rounded : Icons.refresh_rounded,
                        label: canWiden
                            ? (widening ? 'Widening…' : 'Widen my search')
                            : (refreshing ? 'Refreshing…' : 'Refresh'),
                        onPressed: canWiden
                            ? (widening ? null : onWiden)
                            : (refreshing ? null : onRefresh),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onAdjustFilters,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 20),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Adjust filters', style: TextStyle(fontWeight: FontWeight.w700)),
                              if (activeFilterCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    '$activeFilterCount',
                                    style: TextStyle(fontSize: 12, color: scheme.onPrimary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (showRewind) ...[
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: rewinding ? null : onRewind,
                          style: TextButton.styleFrom(foregroundColor: _amber),
                          icon: const Icon(Icons.replay_rounded, size: 18),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Rewind last swipe', style: TextStyle(fontWeight: FontWeight.w600)),
                              if (rewindLocked) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.lock_rounded, size: 14),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StackedIcon extends StatelessWidget {
  const _StackedIcon({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final back = BoxDecoration(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
    );
    return SizedBox(
      width: 112,
      height: 144,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: Transform.rotate(angle: -0.21, child: DecoratedBox(decoration: back))),
          Positioned.fill(child: Transform.rotate(angle: 0.21, child: DecoratedBox(decoration: back))),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: context.duo.brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12)],
              ),
              child: Icon(
                filtered ? Icons.tune_rounded : Icons.favorite_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            right: -12,
            top: -12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary.withValues(alpha: 0.4), width: 2),
              ),
              child: Icon(
                filtered ? Icons.search_off_rounded : Icons.check_rounded,
                size: 18,
                color: scheme.primary,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 1, end: 0.55, duration: 1.seconds),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.gradient,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Gradient gradient;
  final Color foreground;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(99)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: foreground)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
