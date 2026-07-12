import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/duo_gradients.dart';
import '../../../core/theme/duo_theme.dart';
import '../splash_preloader.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      DuoColors.backgroundDark,
                      const Color(0xFF151218),
                      DuoColors.surfaceDark,
                    ]
                  : [
                      const Color(0xFFFFF8FB),
                      const Color(0xFFF7F2FF),
                      DuoColors.backgroundLight,
                    ],
            ),
          ),
        ),
        if (isDark)
          const _AmbientOrb(color: Color(0x33E84A7A), top: -60, left: -40, size: 240)
        else
          const _AmbientOrb(color: Color(0x26E84A7A), top: -40, left: -20, size: 200),
        if (isDark)
          const _AmbientOrb(color: Color(0x268B5CF6), top: 0, left: 0, bottom: 80, right: -50, size: 220)
        else
          const _AmbientOrb(color: Color(0x1A8B5CF6), top: 0, left: 0, bottom: 100, right: -30, size: 180),
        if (isDark)
          const _AmbientOrb(color: Color(0x1AD4A574), top: 180, left: 0, right: 30, size: 140),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.1,
              colors: [
                DuoColors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.color,
    required this.size,
    this.top = 0,
    this.left = 0,
    this.bottom,
    this.right,
  });

  final Color color;
  final double top;
  final double left;
  final double size;
  final double? bottom;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: bottom == null ? top : null,
      bottom: bottom,
      left: right == null ? left : null,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1.06, 1.06),
            duration: 3200.ms,
            curve: Curves.easeInOut,
          )
          .fade(begin: 0.65, end: 1, duration: 3200.ms),
    );
  }
}

class SplashLogoMark extends StatelessWidget {
  const SplashLogoMark({super.key, this.exiting = false});

  final bool exiting;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Animate(
      target: exiting ? 1 : 0,
      effects: [
        FadeEffect(
          duration: 400.ms,
          begin: 1,
          end: 0,
          curve: Curves.easeIn,
        ),
        ScaleEffect(
          duration: 400.ms,
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
          curve: Curves.easeIn,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: exiting ? 0 : 1,
                  child: Lottie.asset(
                    SplashPreloader.lottieAsset,
                    fit: BoxFit.contain,
                    repeat: true,
                    frameRate: FrameRate.max,
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: DuoGradients.brandBr,
                    boxShadow: [
                      BoxShadow(
                        color: DuoColors.primary.withValues(alpha: isDark ? 0.45 : 0.28),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.55),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 650.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.72, 0.72),
                      end: const Offset(1, 1),
                      duration: 900.ms,
                      curve: Curves.easeOutBack,
                    )
                    .then(delay: 200.ms)
                    .shimmer(
                      duration: 1800.ms,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => DuoGradients.brand.createShader(bounds),
            child: Text(
              'Duo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 220.ms, duration: 700.ms, curve: Curves.easeOut)
              .slideY(begin: 0.18, end: 0, duration: 700.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 10),
          Text(
            'Find your person',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: isDark
                  ? DuoColors.onSurfaceVariantDark.withValues(alpha: 0.95)
                  : DuoColors.onSurfaceVariantLight,
            ),
          )
              .animate()
              .fadeIn(delay: 420.ms, duration: 650.ms)
              .slideY(begin: 0.12, end: 0, duration: 650.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }
}
