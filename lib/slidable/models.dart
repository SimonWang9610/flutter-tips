import 'package:flutter/widgets.dart';

enum SlideDirection {
  idle,
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

typedef PointsForActions = (Offset, Offset);

class ComputedSizes {
  final RenderBox mainChild;
  final Size mainChildSize;
  final PointsForActions preActionPoints;
  final PointsForActions postActionPoints;
  final int preActionCount;
  final int postActionCount;

  const ComputedSizes({
    required this.mainChild,
    required this.mainChildSize,
    required this.preActionPoints,
    required this.postActionPoints,
    required this.preActionCount,
    required this.postActionCount,
  });

  /// all actions would be laid out with the same [BoxConstraints]
  /// that is averaged by the specific action count
  /// [layoutRatio] determines how many the ratio of the rect would be used to calculate the constraints
  LayoutSizeForAction getActionLayout(
    Axis axis, {
    required ActionPosition position,
    double layoutRatio = 1.0,
  }) {
    final topLeft = position == ActionPosition.pre
        ? preActionPoints.$1
        : postActionPoints.$1;

    final bottomRight = position == ActionPosition.pre
        ? preActionPoints.$2
        : postActionPoints.$2;

    final actionCount =
        position == ActionPosition.pre ? preActionCount : postActionCount;

    final rect = Rect.fromPoints(topLeft, bottomRight);
    final constraints = rect.getConstraints(axis, layoutRatio, actionCount);
    final averageShift = rect.getShiftedOffset(axis, actionCount, layoutRatio);

    return LayoutSizeForAction(
      topLeft: topLeft,
      bottomRight: bottomRight,
      averageShift: averageShift,
      constraints: constraints,
      position: position,
    );
  }
}

enum ActionPosition {
  pre,
  post,
}

/// [averageShift] is the average offset that each action would be shifted along the main axis
/// so its y would be 0 for [Axis.horizontal] and its x would be 0 for [Axis.vertical]
/// [topLeft] and [bottomRight] are relative to the part determined by the main child's size and [SlideController.visibleThreshold]
class LayoutSizeForAction {
  final ActionPosition position;
  final Offset topLeft;
  final Offset bottomRight;
  final Offset averageShift;
  final BoxConstraints constraints;

  const LayoutSizeForAction({
    required this.topLeft,
    required this.bottomRight,
    required this.averageShift,
    required this.constraints,
    required this.position,
  });

  /// for pre actions, their top-left are always based on the same [topLeft]
  /// for post actions, their top-left are based on [topRight] for [Axis.horizontal] or [bottomLeft] for [Axis.vertical]
  Offset getRelativeOffset(int index, double ratio) {
    if (position == ActionPosition.pre) {
      return topLeft + averageShift * index.toDouble() * ratio;
    }

    final topRight = Offset(bottomRight.dx, topLeft.dy);
    final bottomLeft = Offset(topLeft.dx, bottomRight.dy);

    final axis = averageShift.dx == 0 ? Axis.vertical : Axis.horizontal;
    final shift = averageShift * (index + 1) * ratio;

    switch (axis) {
      case Axis.horizontal:
        return topRight - shift;
      case Axis.vertical:
        return bottomLeft - shift;
    }
  }

  @override
  String toString() {
    return 'LayoutSizeForAction(topLeft: $topLeft, bottomRight: $bottomRight, averageShift: $averageShift, constraints: $constraints)';
  }
}

extension ValidateRect on Rect {
  bool get isEmpty {
    return width == 0 || height == 0;
  }

  BoxConstraints getConstraints(Axis axis, double ratio, int count) {
    return switch (axis) {
      Axis.horizontal => BoxConstraints.tightFor(
          width: width * ratio / count,
          height: height,
        ),
      Axis.vertical => BoxConstraints.tightFor(
          width: width,
          height: height * ratio / count,
        ),
    };
  }

  Offset getShiftedOffset(Axis axis, int count, double ratio) {
    if (count == 0) {
      return Offset.zero;
    }

    return switch (axis) {
      Axis.horizontal => Offset(
          width * ratio / count,
          0,
        ),
      Axis.vertical => Offset(
          0,
          height * ratio / count,
        ),
    };
  }
}
