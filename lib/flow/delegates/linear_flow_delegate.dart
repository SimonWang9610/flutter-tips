import 'package:flutter/material.dart';
import 'button_flow_delegate.dart';
import '../models.dart';

class LinearFlowDelegate extends ButtonFlowDelegate<LinearFlowParams> {
  LinearFlowDelegate({
    required Animation<double> animation,
    required LinearFlowParams params,
    alignment = Alignment.center,
  }) : super(animation: animation, alignment: alignment, params: params);

  FlowDirection get direction => params.direction;

  @override
  Offset calculateOffset(Size childSize, int index) {
    double? dx;
    double? dy;

    final effectiveFactor = index * (1 + params.factor);

    switch (direction) {
      case FlowDirection.left:
      case FlowDirection.right:
        dx = childSize.width * effectiveFactor * animation.value;
        break;
      case FlowDirection.down:
      case FlowDirection.up:
        dy = childSize.height * effectiveFactor * animation.value;
        break;
    }
    return Offset(dx ?? 0, dy ?? 0);
  }

  @override
  Matrix4 transform(Offset relativeOffset, Offset anchor) {
    double? verticalOffset;
    double? horizontalOffset;

    switch (direction) {
      case FlowDirection.up:
        verticalOffset = anchor.dy - relativeOffset.dy;
        break;
      case FlowDirection.down:
        verticalOffset = anchor.dy + relativeOffset.dy;
        break;
      case FlowDirection.left:
        horizontalOffset = anchor.dx - relativeOffset.dx;
        break;
      case FlowDirection.right:
        horizontalOffset = anchor.dx + relativeOffset.dx;
        break;
    }

    return Matrix4.translationValues(
      horizontalOffset ?? anchor.dx,
      verticalOffset ?? anchor.dy,
      0,
    );
  }
}
