import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/indicator/circle.dart';

enum ProgressDirection {
  left,
  right,
  top,
  bottom,
}

class LinearProgressPainter extends CustomPainter {
  final Color barColor;
  final Path? clipPath;
  final Animation<double> percentNotifier;
  final ProgressDirection direction;
  final BorderRadius? borderRadius;
  const LinearProgressPainter({
    this.direction = ProgressDirection.left,
    this.clipPath,
    this.borderRadius,
    required this.barColor,
    required this.percentNotifier,
  }) : super(repaint: percentNotifier);

  @override
  bool shouldRepaint(covariant LinearProgressPainter oldDelegate) =>
      barColor != oldDelegate.barColor ||
      percentNotifier != oldDelegate.percentNotifier ||
      clipPath != oldDelegate.clipPath ||
      direction != oldDelegate.direction;

  @override
  void paint(Canvas canvas, Size size) {
    assert(size.isFinite, "Cannot paint with infinite width or height");
    if (size.isEmpty) return;

    final total = switch (direction) {
      ProgressDirection.left || ProgressDirection.right => size.width,
      ProgressDirection.top || ProgressDirection.bottom => size.height,
    };

    if (clipPath != null) {
      canvas.clipPath(clipPath!);
    } else if (borderRadius != null) {
      canvas.clipRRect(
          borderRadius!.resolve(TextDirection.ltr).toRRect(Offset.zero & size));
    }

    final current = total * percentNotifier.value;

    final rect = switch (direction) {
      ProgressDirection.left => Rect.fromLTWH(
          0,
          0,
          current,
          size.height,
        ),
      ProgressDirection.right => Rect.fromLTWH(
          size.width - current,
          0,
          current,
          size.height,
        ),
      ProgressDirection.top => Rect.fromLTWH(
          0,
          0,
          size.width,
          current,
        ),
      ProgressDirection.bottom => Rect.fromLTWH(
          0,
          size.height - current,
          size.width,
          current,
        ),
    };

    canvas.drawRect(rect, Paint()..color = barColor);
  }

  // @override
  // bool hitTest(Offset position) => false;
}

class AnimatedLinearProgressIndicator extends StatefulWidget {
  final int totalSeconds;
  final double percent;
  final ProgressDirection direction;

  final Color barColor;
  final Curve curve;
  final Widget? child;
  final Size? size;

  const AnimatedLinearProgressIndicator({
    super.key,
    required this.totalSeconds,
    required this.percent,
    required this.barColor,
    this.direction = ProgressDirection.left,
    this.curve = Curves.linear,
    this.child,
    this.size,
  }) : assert(percent >= 0 && percent <= 1 && (size != null || child != null));

  @override
  State<AnimatedLinearProgressIndicator> createState() =>
      _AnimatedLinearProgressIndicatorState();
}

class _AnimatedLinearProgressIndicatorState
    extends State<AnimatedLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.totalSeconds),
  );

  late Animation<double> _percentNotifier;

  @override
  void initState() {
    super.initState();
    _updateAnimation();
  }

  void _updateAnimation() {
    _percentNotifier = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.totalSeconds != oldWidget.totalSeconds) {
      _controller.duration = Duration(seconds: widget.totalSeconds);
      _controller.reset();
    }

    if (widget.percent != oldWidget.percent) {
      if (widget.percent == 0) {
        _controller.reset();
      } else {
        _controller.animateTo(widget.percent);
      }
    }

    if (widget.curve != oldWidget.curve) {
      _updateAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: LinearProgressPainter(
        barColor: widget.barColor,
        percentNotifier: _percentNotifier,
        direction: widget.direction,
      ),
      size: widget.size ?? Size.zero,
      child: widget.child,
    );
  }
}

typedef ProgressPainterBuilder = CustomPainter Function(
    Animation<double> percentNotifier);

class AnimatedProgressIndicator extends StatefulWidget {
  final int totalSeconds;
  final double percent;
  final ProgressPainterBuilder progressPainterBuilder;
  final Widget? child;
  final Size? size;
  final Curve curve;
  const AnimatedProgressIndicator({
    super.key,
    required this.totalSeconds,
    required this.percent,
    required this.progressPainterBuilder,
    this.child,
    this.size,
    this.curve = Curves.linear,
  });

  @override
  State<AnimatedProgressIndicator> createState() =>
      _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.totalSeconds),
  );

  late Animation<double> _percentNotifier;

  @override
  void initState() {
    super.initState();
    _updateAnimation();
  }

  void _updateAnimation() {
    _percentNotifier = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.totalSeconds != oldWidget.totalSeconds) {
      _controller.duration = Duration(seconds: widget.totalSeconds);
      _controller.reset();
    }

    if (widget.percent != oldWidget.percent) {
      if (widget.percent == 0) {
        _controller.reset();
      } else {
        _controller.animateTo(widget.percent);
      }
    }

    if (widget.curve != oldWidget.curve) {
      _updateAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: widget.progressPainterBuilder(_percentNotifier),
      size: widget.size ?? Size.zero,
      child: widget.child,
    );
  }
}

class CircularPercentProgressIndicator extends StatelessWidget {
  final Color barColor;
  final double strokeWidth;
  final double startAngle;
  final double? radius;
  final Widget? child;
  final int totalSeconds;
  final double percent;
  const CircularPercentProgressIndicator({
    super.key,
    required this.barColor,
    required this.radius,
    required this.totalSeconds,
    required this.percent,
    this.strokeWidth = 5,
    this.startAngle = -pi / 2,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedProgressIndicator(
      totalSeconds: totalSeconds,
      percent: percent,
      progressPainterBuilder: (percentNotifier) => CircleProgressPainter(
        barColor: barColor,
        percentNotifier: percentNotifier,
        startAngle: startAngle,
        strokeWidth: strokeWidth,
      ),
      size: Size.square((radius ?? 0) * 2),
      child: child,
    );
  }
}

class LinearPercentProgressIndicator extends StatelessWidget {
  final int totalSeconds;
  final double percent;
  final ProgressDirection direction;

  final Color barColor;
  final Curve curve;
  final Widget? child;
  final Size? size;
  final Path? clipPath;
  final BorderRadius? borderRadius;
  const LinearPercentProgressIndicator({
    super.key,
    required this.totalSeconds,
    required this.percent,
    required this.barColor,
    this.direction = ProgressDirection.left,
    this.curve = Curves.linear,
    this.child,
    this.size,
    this.clipPath,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedProgressIndicator(
      totalSeconds: totalSeconds,
      percent: percent,
      progressPainterBuilder: (percentNotifier) => LinearProgressPainter(
        barColor: barColor,
        percentNotifier: percentNotifier,
        direction: direction,
        clipPath: clipPath,
        borderRadius: borderRadius,
      ),
      size: size,
      child: child,
    );
  }
}
