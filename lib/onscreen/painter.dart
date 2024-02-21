import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/onscreen/background.dart';
import 'package:flutter_tips/onscreen/widget.dart';

class PaintConfiguration {
  final Color color;
  final double width;
  final StrokeCap? cap;

  const PaintConfiguration({
    required this.color,
    required this.width,
    this.cap,
  });

  Paint toPaint() {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = cap ?? StrokeCap.butt;
  }
}

class OnscreenBackgroundPainter with DashableLinePainter {
  final PaintConfiguration? border;
  final PaintConfiguration? dash;
  final double? dashLength;

  OnscreenBackgroundPainter({
    this.border,
    this.dash,
    this.dashLength,
  });

  bool shouldRepaint(covariant OnscreenBackgroundPainter old) {
    return border != old.border || dash != old.dash;
  }

  void paint(Canvas canvas, Size size, OnscreenPadding padding) {
    if (border != null) {
      canvas.drawRect(
        Offset.zero & size,
        border!.toPaint(),
      );
    }

    if (dash != null) {
      final paint = dash!.toPaint();

      drawDashLine(
        canvas,
        start: Offset(0, padding.top * size.height),
        end: Offset(size.width, padding.top * size.height),
        paint: paint,
        dashLength: dashLength,
      );

      drawDashLine(
        canvas,
        start: Offset(0, (1 - padding.bottom) * size.height),
        end: Offset(size.width, (1 - padding.bottom) * size.height),
        paint: paint,
        dashLength: dashLength,
      );

      drawDashLine(
        canvas,
        start: Offset((1 - padding.right) * size.width, 0),
        end: Offset((1 - padding.right) * size.width, size.height),
        paint: paint,
        dashLength: dashLength,
      );

      drawDashLine(
        canvas,
        start: Offset(padding.left * size.width, 0),
        end: Offset(padding.left * size.width, size.height),
        paint: paint,
        dashLength: dashLength,
      );
    }
  }
}

class OnscreenFocusNode extends Listenable with DashableLinePainter {
  final PaintConfiguration border;
  final double? dashLength;
  final ValueNotifier<OnscreenPosition?> _focus;

  OnscreenFocusNode({
    required this.border,
    this.dashLength,
    OnscreenPosition? initialFocus,
  }) : _focus = ValueNotifier(initialFocus);

  OnscreenPosition? get focusedPosition => _focus.value;

  OnscreenElement? _focusedElement;
  OnscreenElement? get focusedElement => _focusedElement;

  bool get hasFocus => _focus.value != null;

  void focus(OnscreenPosition position, OnscreenElement? element) {
    if (focusedPosition != position) {
      _focus.value = position;
      _focusedElement = element;
    }
  }

  void unfocus() {
    _focus.value = null;
    _focusedElement = null;
  }

  @override
  void addListener(listener) {
    _focus.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _focus.removeListener(listener);
  }

  void dispose() {
    _focus.dispose();
  }

  void paint(Canvas canvas, Size size, Offset offset) {
    if (size.isEmpty) {
      return;
    }

    if (dashLength == null) {
      canvas.drawRect(
        offset & size,
        border.toPaint(),
      );
    } else {
      final paint = border.toPaint();

      drawDashLine(
        canvas,
        start: offset,
        end: size.topRight(offset),
        paint: paint,
        dashLength: dashLength,
      );

      drawDashLine(
        canvas,
        start: size.topRight(offset),
        end: size.bottomRight(offset),
        paint: paint,
        dashLength: dashLength,
      );

      drawDashLine(
        canvas,
        start: size.bottomRight(offset),
        end: size.bottomLeft(offset),
        paint: paint,
        dashLength: dashLength,
      );

      drawDashLine(
        canvas,
        start: size.bottomLeft(offset),
        end: offset,
        paint: paint,
        dashLength: dashLength,
      );

      print("${size.bottomLeft(offset)} -> $offset");
    }
  }

  bool shouldRepaint(covariant OnscreenFocusNode old) {
    return border != old.border || dashLength != old.dashLength;
  }
}

mixin class DashableLinePainter {
  void drawDashLine(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required Paint paint,
    double? dashLength,
  }) {
    if (dashLength == null || dashLength == 0) {
      canvas.drawLine(start, end, paint);
      return;
    }

    final shift = getDashShift(start, end, dashLength);

    Offset current = start;

    while (true) {
      final next = current + shift;

      if (!insideLine(start, end, next)) {
        canvas.drawLine(current, end, paint);
        break;
      }

      canvas.drawLine(current, next, paint);

      current = current + shift * 2;
    }
  }

  Offset getDashShift(Offset start, Offset end, double dashLength) {
    if (start.dx == end.dx) {
      return Offset(0, dashLength * (end.dy - start.dy).sign);
    } else if (start.dy == end.dy) {
      return Offset(dashLength * (end.dx - start.dx).sign, 0);
    }

    final distance =
        sqrt(pow(end.dx - start.dx, 2) + pow(end.dy - start.dy, 2));

    return Offset(
      (end.dx - start.dx) / distance * dashLength,
      (end.dy - start.dy) / distance * dashLength,
    );
  }

  bool insideLine(Offset start, Offset end, Offset point) {
    final insideX = (point.dx - start.dx) * (point.dx - end.dx) <= 0;
    final insideY = (point.dy - start.dy) * (point.dy - end.dy) <= 0;

    return insideX && insideY;
  }
}
