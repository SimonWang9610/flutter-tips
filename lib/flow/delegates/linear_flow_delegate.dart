import 'package:flutter/material.dart';
import 'button_flow_delegate.dart';
import '../models.dart';

class LinearFlowDelegate extends ButtonFlowDelegate {
  final FlowDirection direction;
  final double buttonGap;

  LinearFlowDelegate({
    required super.animation,
    this.direction = FlowDirection.right,
    super.alignment = Alignment.center,
    this.buttonGap = 10,
  });

  @override
  bool shouldRepaint(covariant LinearFlowDelegate oldDelegate) {
    return super.shouldRepaint(oldDelegate) ||
        direction != oldDelegate.direction ||
        buttonGap != oldDelegate.buttonGap;
  }

  final List<Offset> _childrenOffsets = [Offset.zero];

  /// [_childrenOffsets] record the offset of (top-left of each child + each child's width/height determined by [FlowDirection]
  /// therefore, for [index]-th [FlowEntry], it will refer to its previous position to calculate its top-left offset
  /// then store (its top-left [offset] + [shift]) in [_childrenOffsets]
  /// the reason why we need to add [shift] is to ease calculating the next child's position
  /// because we do not need to know its previous child's [Size]
  @override
  Offset calculateOffset(Size childSize, int index) {
    double? dx;
    double? dy;
    double shiftX = 0.0;
    double shiftY = 0.0;

    final Offset previousOffset =
        _childrenOffsets.length > index ? _childrenOffsets[index] : Offset.zero;

    switch (direction) {
      case FlowDirection.left:
      case FlowDirection.right:
        dx = (previousOffset.dx + buttonGap) * animation.value;
        shiftX = childSize.width;
        break;
      case FlowDirection.down:
      case FlowDirection.up:
        dy = (previousOffset.dy + buttonGap) * animation.value;
        shiftY = childSize.height;
        break;
    }

    final offset = Offset(dx ?? 0, dy ?? 0);
    final shift = Offset(shiftX, shiftY);

    if (_childrenOffsets.length <= (index + 1)) {
      _childrenOffsets.add(offset + shift);
    } else {
      _childrenOffsets[index + 1] = offset + shift;
    }
    return offset;
  }

  @override
  Matrix4 transform(Offset relativeOffset, Offset origin) {
    double? verticalOffset;
    double? horizontalOffset;

    switch (direction) {
      case FlowDirection.up:
        verticalOffset = origin.dy - relativeOffset.dy;
        break;
      case FlowDirection.down:
        verticalOffset = origin.dy + relativeOffset.dy;
        break;
      case FlowDirection.left:
        horizontalOffset = origin.dx - relativeOffset.dx;
        break;
      case FlowDirection.right:
        horizontalOffset = origin.dx + relativeOffset.dx;
        break;
    }

    return Matrix4.translationValues(
      horizontalOffset ?? origin.dx,
      verticalOffset ?? origin.dy,
      0,
    );
  }
}
