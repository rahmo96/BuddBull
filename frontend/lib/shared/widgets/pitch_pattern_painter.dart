import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Abstract stadium / pitch line overlay for gradient headers.
class PitchPatternPainter extends CustomPainter {
  PitchPatternPainter({this.lineColor = const Color(0x18FFFFFF)});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width * 0.72, size.height * 0.55);
    final radius = size.width * 0.38;

    canvas.drawCircle(center, radius, paint);
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );

    final boxW = radius * 0.55;
    final boxH = radius * 0.7;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: boxW, height: boxH),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.35),
      paint..strokeWidth = 0.8,
    );

    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i - 2) * 0.35;
      final start = center +
          Offset(math.cos(angle) * radius * 0.3, math.sin(angle) * radius * 0.3);
      final end = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawLine(start, end, paint..strokeWidth = 0.9);
    }
  }

  @override
  bool shouldRepaint(covariant PitchPatternPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
