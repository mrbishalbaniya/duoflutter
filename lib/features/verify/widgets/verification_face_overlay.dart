import 'dart:math' as math;

import 'package:flutter/material.dart';

class VerificationFaceOverlay extends StatelessWidget {
  const VerificationFaceOverlay({
    super.key,
    required this.statusMessage,
    required this.progress,
    this.showPulse = true,
  });

  final String statusMessage;
  final double progress;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _FaceGuidePainter(progress: progress, showPulse: showPulse)),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  _FaceGuidePainter({required this.progress, required this.showPulse});

  final double progress;
  final bool showPulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final ovalWidth = size.width * 0.62;
    final ovalHeight = size.height * 0.48;
    final rect = Rect.fromCenter(center: center, width: ovalWidth, height: ovalHeight);

    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()..addOval(rect);
    canvas.drawPath(Path.combine(PathOperation.difference, full, hole), scrim);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawOval(rect, ring);

    if (showPulse) {
      final pulse = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFE84A7A).withValues(alpha: 0.55);
      final scale = 1 + (math.sin(progress * math.pi * 2) * 0.02);
      final pulseRect = Rect.fromCenter(
        center: center,
        width: ovalWidth * scale,
        height: ovalHeight * scale,
      );
      canvas.drawOval(pulseRect, pulse);
    }

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD4A574);

    const corner = 22.0;
    final left = rect.left;
    final right = rect.right;
    final top = rect.top;
    final bottom = rect.bottom;

    canvas.drawLine(Offset(left, top + corner), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + corner, top), cornerPaint);

    canvas.drawLine(Offset(right - corner, top), Offset(right, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + corner), cornerPaint);

    canvas.drawLine(Offset(left, bottom - corner), Offset(left, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + corner, bottom), cornerPaint);

    canvas.drawLine(Offset(right - corner, bottom), Offset(right, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - corner), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.showPulse != showPulse;
  }
}
