import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/duo_gradients.dart';
import '../../../core/theme/duo_theme.dart';
import '../onboarding_models.dart';

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.page,
    required this.isActive,
  });

  final OnboardingPageData page;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(220.0, 360.0);
        return SizedBox(
          height: size * 0.92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _OrbitRing(
                size: size * 0.92,
                color: page.accent.withValues(alpha: 0.12),
                active: isActive,
              ),
              _OrbitRing(
                size: size * 0.72,
                color: DuoColors.tertiary.withValues(alpha: 0.1),
                active: isActive,
                delayMs: 120,
              ),
              _buildIllustrationBody(size),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIllustrationBody(double size) {
    switch (page.id) {
      case 'welcome':
        return _WelcomeIllustration(page: page, size: size * 0.56, active: isActive);
      case 'discover':
        return _SwipeCardsIllustration(page: page, size: size * 0.62, active: isActive);
      case 'match':
        return _SparkleIllustration(page: page, size: size * 0.58, active: isActive);
      case 'chat':
        return _ChatIllustration(page: page, size: size * 0.58, active: isActive);
      default:
        return _WelcomeIllustration(page: page, size: size * 0.56, active: isActive);
    }
  }
}

class _OrbitRing extends StatelessWidget {
  const _OrbitRing({
    required this.size,
    required this.color,
    required this.active,
    this.delayMs = 0,
  });

  final double size;
  final Color color;
  final bool active;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    )
        .animate(target: active ? 1 : 0)
        .scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1, 1),
          duration: 700.ms,
          delay: delayMs.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 500.ms, delay: delayMs.ms);
  }
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration({
    required this.page,
    required this.size,
    required this.active,
  });

  final OnboardingPageData page;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: page.heroTag,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: DuoGradients.brandBr,
            boxShadow: [
              BoxShadow(
                color: page.accent.withValues(alpha: 0.35),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Icon(page.icon, color: Colors.white, size: size * 0.38),
        ),
      ),
    )
        .animate(target: active ? 1 : 0)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 650.ms,
          curve: Curves.easeOutBack,
        )
        .shimmer(
          duration: 1800.ms,
          color: Colors.white.withValues(alpha: 0.2),
        );
  }
}

class _SwipeCardsIllustration extends StatelessWidget {
  const _SwipeCardsIllustration({
    required this.page,
    required this.size,
    required this.active,
  });

  final OnboardingPageData page;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: page.heroTag,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: size,
          height: size * 1.15,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _MiniCard(
                width: size * 0.72,
                height: size * 0.92,
                rotation: -0.12,
                color: DuoColors.surfaceContainerHighDark,
                offset: const Offset(-18, 10),
                active: active,
                delay: 0,
              ),
              _MiniCard(
                width: size * 0.76,
                height: size * 0.96,
                rotation: 0.08,
                gradient: DuoGradients.brand,
                offset: const Offset(16, -8),
                active: active,
                delay: 80,
                child: Icon(page.icon, color: Colors.white, size: 42),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.width,
    required this.height,
    required this.rotation,
    required this.offset,
    required this.active,
    required this.delay,
    this.color,
    this.gradient,
    this.child,
  });

  final double width;
  final double height;
  final double rotation;
  final Offset offset;
  final bool active;
  final int delay;
  final Color? color;
  final Gradient? gradient;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    )
        .animate(target: active ? 1 : 0)
        .fadeIn(duration: 500.ms, delay: delay.ms)
        .slideY(begin: 0.08, end: 0, duration: 550.ms, delay: delay.ms, curve: Curves.easeOut);
  }
}

class _SparkleIllustration extends StatelessWidget {
  const _SparkleIllustration({
    required this.page,
    required this.size,
    required this.active,
  });

  final OnboardingPageData page;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: page.heroTag,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    page.accent.withValues(alpha: 0.25),
                    DuoColors.primary.withValues(alpha: 0.18),
                  ],
                ),
                border: Border.all(color: page.accent.withValues(alpha: 0.25)),
              ),
              child: Icon(page.icon, color: Colors.white, size: size * 0.34),
            ),
            Positioned(
              top: size * 0.08,
              right: size * 0.06,
              child: _SparkleDot(color: DuoColors.accent, active: active),
            ),
            Positioned(
              bottom: size * 0.12,
              left: size * 0.08,
              child: _SparkleDot(color: DuoColors.love, active: active, delay: 100),
            ),
          ],
        ),
      ),
    )
        .animate(target: active ? 1 : 0)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 600.ms);
  }
}

class _SparkleDot extends StatelessWidget {
  const _SparkleDot({
    required this.color,
    required this.active,
    this.delay = 0,
  });

  final Color color;
  final bool active;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star_rounded, color: color, size: 22)
        .animate(target: active ? 1 : 0, onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.15, 1.15),
          duration: 1200.ms,
          delay: delay.ms,
        )
        .fade(begin: 0.5, end: 1, duration: 1200.ms, delay: delay.ms);
  }
}

class _ChatIllustration extends StatelessWidget {
  const _ChatIllustration({
    required this.page,
    required this.size,
    required this.active,
  });

  final OnboardingPageData page;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: page.heroTag,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: size,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: DuoColors.surfaceContainerHighDark.withValues(alpha: 0.85),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChatBubble(alignRight: false, active: active, delay: 0, text: 'Namaste!'),
              const SizedBox(height: 10),
              _ChatBubble(alignRight: true, active: active, delay: 120, text: 'Great to meet you'),
              const SizedBox(height: 10),
              _ChatBubble(alignRight: false, active: active, delay: 240, text: 'Coffee in Thamel?'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.alignRight,
    required this.active,
    required this.delay,
    required this.text,
  });

  final bool alignRight;
  final bool active;
  final int delay;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(alignRight ? 18 : 4),
            bottomRight: Radius.circular(alignRight ? 4 : 18),
          ),
          gradient: alignRight ? DuoGradients.brandBr : null,
          color: alignRight ? null : DuoColors.surfaceVariantDark,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: alignRight ? Colors.white : DuoColors.onSurfaceDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    )
        .animate(target: active ? 1 : 0)
        .fadeIn(duration: 400.ms, delay: delay.ms)
        .slideX(
          begin: alignRight ? 0.12 : -0.12,
          end: 0,
          duration: 450.ms,
          delay: delay.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
