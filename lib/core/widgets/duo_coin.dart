import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A drawn gold Duo Coin (rim, reeded edge, shine and an embossed "D"),
/// used wherever web shows the 🪙 coin.
class DuoCoin extends StatelessWidget {
  const DuoCoin({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Duo coins',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _CoinPainter()),
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  static const _rimDark = Color(0xFFA86B0C);
  static const _rimLight = Color(0xFFF7C948);
  static const _faceLight = Color(0xFFFFE27A);
  static const _faceMid = Color(0xFFF5B82E);
  static const _faceDark = Color(0xFFD48A12);
  static const _emboss = Color(0xFFB8740A);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Soft drop shadow.
    canvas.drawCircle(
      c.translate(0, r * 0.08),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );

    // Outer rim.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_rimLight, _rimDark],
        ).createShader(rect),
    );

    // Reeded edge ticks (only when large enough to see).
    if (r >= 14) {
      final tick = Paint()
        ..color = _rimDark.withValues(alpha: 0.55)
        ..strokeWidth = math.max(0.6, r * 0.03);
      const count = 36;
      for (var i = 0; i < count; i++) {
        final a = i * 2 * math.pi / count;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(c + dir * (r * 0.86), c + dir * (r * 0.97), tick);
      }
    }

    // Face.
    final faceR = r * 0.82;
    final faceRect = Rect.fromCircle(center: c, radius: faceR);
    canvas.drawCircle(
      c,
      faceR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 1.0,
          colors: [_faceLight, _faceMid, _faceDark],
          stops: [0, 0.55, 1],
        ).createShader(faceRect),
    );

    // Inner ring.
    canvas.drawCircle(
      c,
      faceR * 0.86,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.05)
        ..color = _emboss.withValues(alpha: 0.55),
    );

    // Embossed "D": a light offset copy under a darker one reads as relief.
    void drawD(Color color, Offset shift) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'D',
          style: TextStyle(
            color: color,
            fontSize: faceR * 1.15,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2) + shift);
    }

    drawD(_faceLight.withValues(alpha: 0.9), Offset(r * 0.03, r * 0.04));
    drawD(_emboss, Offset.zero);

    // Shine.
    final shine = Path()
      ..addArc(Rect.fromCircle(center: c, radius: faceR * 0.92), math.pi * 1.05, math.pi * 0.5);
    canvas.drawPath(
      shine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1, r * 0.09)
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
