import 'dart:math';

import 'package:flutter/material.dart';

mixin CircularLayoutMixin on FlowDelegate {
  double? get startAngle;
  Alignment get alignment;
  Animation<double> get animation;

  Offset calculateOffset(
      Size childSize, double radius, int index, double perRad) {
    if (index == 0) {
      return Offset.zero;
    }

    final effectiveAngle = (index - 1) * perRad - (startAngle ?? 0);

    final dx =
        (radius - childSize.width / 2) * cos(effectiveAngle) * animation.value;
    final dy =
        (radius - childSize.height / 2) * sin(effectiveAngle) * animation.value;

    return Offset(dx, dy);
  }

  Matrix4 createTransform(Offset relativeOffset, Offset anchor) {
    return Matrix4.translationValues(
      anchor.dx + relativeOffset.dx,
      anchor.dy + relativeOffset.dy,
      0,
    );
  }

  Offset getAnchorOffset(Size parentSize, Size entrySize) {
    // final Offset offset = Offset(-entrySize.width / 2, -entrySize.height / 2);

    final relativeOffset = alignment.alongSize(entrySize);

    // print('offset: $offset, relative: $relativeOffset');
    return alignment.alongSize(parentSize) - relativeOffset;
  }
}
