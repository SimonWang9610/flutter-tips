import 'package:flutter/material.dart';

abstract class ButtonFlowDelegate extends FlowDelegate {
  final Animation<double> animation;
  final Alignment alignment;
  ButtonFlowDelegate({
    required this.animation,
    this.alignment = Alignment.center,
  }) : super(repaint: animation);

  @override
  bool shouldRepaint(covariant ButtonFlowDelegate oldDelegate) {
    return animation != oldDelegate.animation ||
        alignment != oldDelegate.alignment;
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

    final alignedOrigin = alignMainEntry(context.size, mainEntrySize);

    if (animation.value == 0) {
      print('paint first child');
      context.paintChild(
        0,
        transform: transform(Offset.zero, alignedOrigin),
      );
      return;
    }

    for (int i = 0; i < context.childCount; i++) {
      final childSize = context.getChildSize(i) ?? Size.zero;

      final childOffset = calculateOffset(childSize, i);

      context.paintChild(
        i,
        transform: transform(childOffset, alignedOrigin),
      );
    }
  }

  /// get the translation distance from the centre of the entry to the specific position determined by [alignment] and [parentSize]

  Offset alignMainEntry(Size parentSize, Size entrySize) {
    final relativeOffset = alignment.alongSize(entrySize);

    return alignment.alongSize(parentSize) - relativeOffset;
  }

  Offset calculateOffset(Size childSize, int index);

  /// calculate the position for each entry based the aligned [origin] and the relative offset calculated by [calculateOffset]
  Matrix4 transform(Offset relativeOffset, Offset origin);
}
