import 'package:flutter/material.dart';

enum FlowDirection {
  left,
  right,
  up,
  down,
}

enum FlowType {
  linear,
  circular,
}

class FlowEntry {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  FlowEntry({
    required this.child,
    this.onPressed,
    this.style,
  });
}

abstract class FlowTypeParams {
  /// if true, it will set the first child as the main button

  final bool autoFill;
  FlowTypeParams(this.autoFill);
}

class CircularFlowParams extends FlowTypeParams {
  final double angle;
  final double startAngle;
  final double radius;
  CircularFlowParams({
    required this.radius,
    required this.angle,
    this.startAngle = 0,
    autoFill = true,
  }) : super(autoFill);

  @override
  bool operator ==(covariant CircularFlowParams other) {
    return autoFill == other.autoFill &&
        angle == other.angle &&
        startAngle == other.startAngle &&
        radius == other.radius;
  }
}

class LinearFlowParams extends FlowTypeParams {
  final double factor;
  final FlowDirection direction;
  LinearFlowParams({
    this.direction = FlowDirection.down,
    this.factor = 0,
    bool autoFill = true,
  }) : super(autoFill);

  @override
  bool operator ==(covariant LinearFlowParams other) {
    return direction == other.direction &&
        autoFill == other.autoFill &&
        factor == other.factor;
  }
}
