import 'package:flutter/material.dart';
import 'package:flutter_tips/flow/models.dart';

abstract class ButtonFlowDelegate<T extends FlowTypeParams>
    extends FlowDelegate {
  final Animation<double> animation;
  final Alignment alignment;
  final T params;
  ButtonFlowDelegate({
    required this.animation,
    required this.params,
    this.alignment = Alignment.center,
  }) : super(repaint: animation);

  @override
  bool shouldRepaint(covariant ButtonFlowDelegate oldDelegate) {
    print('should repaint');
    return animation != oldDelegate.animation;
  }

  /// must ensure the constraint of children is loosen;
  /// in [Flex]-like widgets, it may pass its uncompleted loosen constraints, like (0<=w<=100, h=100)
  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Size getSize(BoxConstraints constraints) {
    assert(constraints.hasBoundedHeight || constraints.hasBoundedWidth,
        'Must give one of bounded sides in BoxConstraints');
    final biggestSize = constraints.biggest;
    // print('constrains: $constraints, size: $biggestSize');

    if (biggestSize.isInfinite) {
      final side = biggestSize.shortestSide;

      return Size(side, side);
    } else {
      return biggestSize;
    }
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final mainEntrySize = context.getChildSize(0) ?? Size.zero;

    final anchor = getAnchorOffset(context.size, mainEntrySize);

    if (params.autoFill && animation.value == 0) {
      print('paint first child');
      context.paintChild(
        0,
        transform: transform(Offset.zero, anchor),
      );
      return;
    }

    for (int i = 0; i < context.childCount; i++) {
      final childSize = context.getChildSize(i) ?? Size.zero;

      final childOffset = calculateOffset(childSize, i);

      context.paintChild(
        i,
        transform: transform(childOffset, anchor),
      );
    }
  }

  Offset getAnchorOffset(Size parentSize, Size entrySize) {
    final relativeOffset = alignment.alongSize(entrySize);

    return alignment.alongSize(parentSize) - relativeOffset;
  }

  Offset calculateOffset(Size childSize, int index);

  Matrix4 transform(Offset relativeOffset, Offset anchor);
}
