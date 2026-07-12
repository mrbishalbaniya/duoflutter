import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/verification_face_guide.dart';

class VerificationFaceOverlay extends StatelessWidget {
  const VerificationFaceOverlay({
    super.key,
    required this.guideState,
    required this.instruction,
    required this.progress,
    this.showScanLine = true,
  });

  final FaceGuideState guideState;
  final String instruction;
  final double progress;
  final bool showScanLine;

  @override
  Widget build(BuildContext context) {
    final accent = guideState.accentColor;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _FaceGuidePainter(
              progress: progress,
              guideState: guideState,
              showScanLine: showScanLine && guideState != FaceGuideState.error,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _IndicatorChip(
                  icon: Icons.face_retouching_natural_rounded,
                  label: guideState == FaceGuideState.ready ? 'Face detected' : 'Align face',
                  active: guideState == FaceGuideState.ready,
                  color: accent,
                ),
                const Spacer(),
                _IndicatorChip(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Lighting',
                  active: guideState != FaceGuideState.error,
                  color: accent,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.82),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusPill(
                      label: guideState.label,
                      instruction: instruction,
                      color: accent,
                      pulse: guideState.pulseDot,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorChip extends StatelessWidget {
  const _IndicatorChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: active ? 0.85 : 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? color : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: active ? 1 : 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatefulWidget {
  const _StatusPill({
    required this.label,
    required this.instruction,
    required this.color,
    required this.pulse,
  });

  final String label;
  final String instruction;
  final Color color;
  final bool pulse;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill> with SingleTickerProviderStateMixin {
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: widget.color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _dotController,
              builder: (context, child) {
                final scale = widget.pulse ? 0.85 + (_dotController.value * 0.3) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.instruction,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  _FaceGuidePainter({
    required this.progress,
    required this.guideState,
    required this.showScanLine,
  });

  final double progress;
  final FaceGuideState guideState;
  final bool showScanLine;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);
    final ovalWidth = size.width * 0.72;
    final ovalHeight = size.height * 0.52;
    final rect = Rect.fromCenter(center: center, width: ovalWidth, height: ovalHeight);
    final accent = guideState.accentColor;

    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.48);
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()..addOval(rect);
    canvas.drawPath(Path.combine(PathOperation.difference, full, hole), scrim);

    final ready = guideState == FaceGuideState.ready || guideState == FaceGuideState.capturing;
    final pulseAlpha = ready ? 0.95 : 0.65 + (math.sin(progress * math.pi * 2) * 0.2);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ready ? 3.5 : 2.5
      ..color = accent.withValues(alpha: pulseAlpha);

    if (ready) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent.withValues(alpha: 0.35);
      canvas.drawOval(rect.inflate(6), glow);
      canvas.drawOval(rect, ring);
    } else {
      _drawDashedOval(canvas, rect, ring);
    }

    if (showScanLine) {
      final scanY = rect.top + (progress * rect.height);
      final scanPaint = Paint()
        ..strokeWidth = 2
        ..shader = LinearGradient(
          colors: [
            accent.withValues(alpha: 0),
            accent.withValues(alpha: 0.85),
            accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(rect.left, scanY - 2, rect.width, 4));
      canvas.drawLine(Offset(rect.left + 12, scanY), Offset(rect.right - 12, scanY), scanPaint);
    }

    if (guideState == FaceGuideState.ready) {
      final check = Paint()
        ..color = accent.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final cx = rect.right - 18;
      final cy = rect.top + 18;
      canvas.drawCircle(Offset(cx, cy), 14, Paint()..color = Colors.black.withValues(alpha: 0.55));
      canvas.drawCircle(Offset(cx, cy), 14, check..style = PaintingStyle.stroke);
    }
  }

  void _drawDashedOval(Canvas canvas, Rect rect, Paint paint) {
    const dash = 12.0;
    const gap = 8.0;
    final path = Path()..addOval(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.guideState != guideState ||
        oldDelegate.showScanLine != showScanLine;
  }
}
