import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme_extensions.dart';

/// One step of the Match coach-mark tour (web `MatchTour`).
class MatchTourStep {
  const MatchTourStep({required this.target, required this.icon, required this.title, required this.body});

  final GlobalKey target;
  final IconData icon;
  final String title;
  final String body;
}

/// Spotlight tour: dims the screen, glides a highlight between targets and
/// shows a card with progress dots, Back / Next and Skip.
class MatchTourOverlay extends StatefulWidget {
  const MatchTourOverlay({super.key, required this.steps, required this.onFinish});

  final List<MatchTourStep> steps;
  final VoidCallback onFinish;

  @override
  State<MatchTourOverlay> createState() => _MatchTourOverlayState();
}

class _MatchTourOverlayState extends State<MatchTourOverlay> with SingleTickerProviderStateMixin {
  static const _padding = 8.0;
  static const _cardHeight = 210.0;
  int _index = 0;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  /// Steps whose target is on screen right now (e.g. no card when the deck is empty).
  List<MatchTourStep> get _visibleSteps =>
      widget.steps.where((s) => s.target.currentContext?.findRenderObject() is RenderBox).toList();

  Rect? _targetRect(MatchTourStep step) {
    final target = step.target.currentContext?.findRenderObject();
    final self = context.findRenderObject();
    if (target is! RenderBox || self is! RenderBox || !target.hasSize) return null;
    final topLeft = target.localToGlobal(Offset.zero, ancestor: self);
    return (topLeft & target.size).inflate(_padding);
  }

  @override
  void initState() {
    super.initState();
    // Targets are laid out after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _go(int index) {
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _visibleSteps;
    if (steps.isEmpty) return const SizedBox.shrink();
    final index = _index.clamp(0, steps.length - 1);
    final step = steps[index];
    final rect = _targetRect(step);
    final scheme = Theme.of(context).colorScheme;
    final duo = context.duo;
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final last = index + 1 >= steps.length;

    // Card below the target if it fits, else above; for a target too tall
    // for either (the profile card) sit over its middle.
    final bottomLimit = size.height - insets.bottom - 16;
    final double cardTop;
    if (rect == null) {
      cardTop = size.height / 2 - _cardHeight / 2;
    } else if (rect.bottom + 14 + _cardHeight < bottomLimit) {
      cardTop = rect.bottom + 14;
    } else if (rect.top - 14 - _cardHeight > insets.top + 12) {
      cardTop = rect.top - 14 - _cardHeight;
    } else {
      cardTop = rect.center.dy - _cardHeight / 2;
    }

    return Stack(
      children: [
        // Scrim + spotlight that glides between targets.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Tapping the dim area moves on, like most coach marks.
            onTap: last ? widget.onFinish : () => _go(index + 1),
            // No target on screen: plain scrim (a Tween needs a non-null end).
            child: rect == null
                ? CustomPaint(painter: _SpotlightPainter(hole: null, ring: scheme.primary, glow: 0))
                : TweenAnimationBuilder<Rect?>(
                    tween: RectTween(end: rect),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedRect, _) => AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) => CustomPaint(
                        painter: _SpotlightPainter(
                          hole: animatedRect,
                          ring: scheme.primary,
                          glow: 0.25 + 0.35 * _pulse.value,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          left: 16,
          right: 16,
          top: cardTop,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: Material(
              key: ValueKey(index),
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              elevation: 10,
              shadowColor: scheme.primary.withValues(alpha: 0.3),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(gradient: duo.brandGradient, shape: BoxShape.circle),
                          child: Icon(step.icon, color: Colors.white, size: 21),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close guide',
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onFinish,
                          icon: Icon(Icons.close_rounded, size: 20, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(step.body, style: TextStyle(fontSize: 14.5, color: scheme.onSurfaceVariant, height: 1.45)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Progress dots.
                        for (var i = 0; i < steps.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 5),
                            width: i == index ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              gradient: i == index ? duo.brandGradient : null,
                              color: i == index ? null : scheme.onSurfaceVariant.withValues(alpha: 0.25),
                            ),
                          ),
                        const Spacer(),
                        if (index > 0)
                          TextButton(onPressed: () => _go(index - 1), child: const Text('Back')),
                        const SizedBox(width: 4),
                        DecoratedBox(
                          decoration: BoxDecoration(gradient: duo.brandGradient, borderRadius: BorderRadius.circular(99)),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            onPressed: last ? widget.onFinish : () => _go(index + 1),
                            child: Text(last ? 'Got it' : 'Next', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.ring, required this.glow});

  final Rect? hole;
  final Color ring;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()..addRect(Offset.zero & size);
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.7);
    if (hole == null) {
      canvas.drawPath(scrim, dim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole!, const Radius.circular(22));
    canvas.drawPath(Path.combine(PathOperation.difference, scrim, Path()..addRRect(rrect)), dim);
    // Soft pulsing glow + crisp ring around the target.
    canvas.drawRRect(
      rrect.inflate(3),
      Paint()
        ..color = ring.withValues(alpha: glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole || old.ring != ring || old.glow != glow;
}

/// Small "?" button that replays the tour (web `MatchHelpButton`).
class MatchHelpButton extends StatelessWidget {
  const MatchHelpButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'How Match works',
      child: Material(
        color: scheme.primary.withValues(alpha: 0.12),
        shape: CircleBorder(side: BorderSide(color: scheme.primary.withValues(alpha: 0.35))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(Icons.question_mark_rounded, size: 14, color: scheme.primary),
          ),
        ),
      ),
    );
  }
}
