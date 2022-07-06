import 'package:flutter/material.dart';

import 'models.dart';

mixin LinearLayoutMixin on FlowDelegate {
  FlowDirection get direction;
  Alignment get alignment;
  Animation<double> get animation;

  Offset getAnchorOffset(Size parentSize, Size entrySize) {
    final relativeOffset = alignment.alongSize(entrySize);

    return alignment.alongSize(parentSize) - relativeOffset;
  }

  /// calculate the offset relative to the [anchor] when changing during animation
  Offset calculateOffset(Offset anchor, Size childSize, int index) {
    double? dx;
    double? dy;

    switch (direction) {
      case FlowDirection.left:
      case FlowDirection.right:
        dx = childSize.width * index * animation.value;
        break;
      case FlowDirection.down:
      case FlowDirection.up:
        dy = childSize.height * index * animation.value;
        break;
    }
    return Offset(dx ?? 0, dy ?? 0);
  }

  /// translate the child to the specific position based on [anchor] and itself offset calculated during animation by [calculateOffset]
  Matrix4 createTransform(double dx, double dy, Offset anchor) {
    double? verticalOffset;
    double? horizontalOffset;

    switch (direction) {
      case FlowDirection.up:
        verticalOffset = anchor.dy - dy;
        break;
      case FlowDirection.down:
        verticalOffset = anchor.dy + dy;
        break;
      case FlowDirection.left:
        horizontalOffset = anchor.dx - dx;
        break;
      case FlowDirection.right:
        horizontalOffset = anchor.dx + dx;
        break;
    }

    return Matrix4.translationValues(
      horizontalOffset ?? anchor.dx,
      verticalOffset ?? anchor.dy,
      0,
    );
  }
}
