import 'dart:math';
import 'package:flutter/material.dart';
import 'button_flow_delegate.dart';
import '../models.dart';

class CircularFlowDelegate extends ButtonFlowDelegate<CircularFlowParams> {
  double? perRad;

  CircularFlowDelegate({
    required Animation<double> animation,
    required CircularFlowParams params,
    alignment = Alignment.center,
  }) : super(animation: animation, alignment: alignment, params: params);

  double get angle => params.angle;
  double get startAngle => params.startAngle;
  double get radius => params.radius;

  @override
  void paintChildren(FlowPaintingContext context) {
    calculatePerRad(context.childCount);
    super.paintChildren(context);
  }

  @override
  Offset calculateOffset(Size childSize, int index) {
    assert(perRad != null, 'have no [perRad] for each child');

    if (params.autoFill && index == 0) {
      return Offset.zero;
    }

    final effectiveAngle =
        (params.autoFill ? index - 1 : index) * perRad! - startAngle;

    // print('$index: $effectiveAngle, animation: ${animation.value}');

    final dx =
        (radius - childSize.width / 2) * cos(effectiveAngle) * animation.value;
    final dy =
        (radius - childSize.height / 2) * sin(effectiveAngle) * animation.value;
    return Offset(dx, dy);
  }

  @override
  Matrix4 transform(Offset relativeOffset, Offset anchor) {
    return Matrix4.translationValues(
      anchor.dx + relativeOffset.dx,
      anchor.dy + relativeOffset.dy,
      0,
    );
  }

  void calculatePerRad(int count) {
    double divisor = 1;

    if (count > 2) {
      divisor = params.autoFill ? count - 2 : count - 1;
    }

    perRad ??= angle / 180 * pi / divisor;
  }
}
