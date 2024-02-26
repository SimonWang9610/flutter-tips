import 'dart:math';

import 'package:flutter/material.dart';

class CircleProgressPainter extends CustomPainter {
  final Color barColor;
  final double strokeWidth;
  final double startAngle;
  final Animation<double> percentNotifier;
  const CircleProgressPainter({
    required this.barColor,
    required this.percentNotifier,
    this.strokeWidth = 2,
    this.startAngle = -pi / 2,
  }) : super(repaint: percentNotifier);

  @override
  bool shouldRepaint(covariant CircleProgressPainter oldDelegate) =>
      barColor != oldDelegate.barColor ||
      percentNotifier != oldDelegate.percentNotifier ||
      strokeWidth != oldDelegate.strokeWidth ||
      startAngle != oldDelegate.startAngle;

  @override
  void paint(Canvas canvas, Size size) {
    assert(size.isFinite, "Cannot paint with infinite width or height");
    if (size.isEmpty) return;

    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2,
    );
    final sweepAngle = 2 * pi * percentNotifier.value;

    final paint = Paint()
      ..color = barColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }
}
