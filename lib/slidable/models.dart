import 'package:flutter/widgets.dart';

enum SlideDirection {
  idle,
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
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

class LayoutSize {
  final Size size;
  final int preActionCount;
  final int postActionCount;

  const LayoutSize({
    required this.size,
    required this.preActionCount,
    required this.postActionCount,
  });

  /// if no action, return null
  /// by doing so, we could disable sliding if no actions along the [axis]
  double? getRatio(Axis axis, double dragExtent) {
    if ((dragExtent > 0 && preActionCount == 0) ||
        (dragExtent < 0 && postActionCount == 0)) {
      return null;
    }

    final mainAxis = axis == Axis.horizontal ? size.width : size.height;
    final ratio = dragExtent / mainAxis;
    return ratio;
  }

  /// [ratio] > 0  indicates we are sliding to see the pre actions
  /// [ratio] < 0  indicates we are sliding to see the post actions
  double getToggleTarget(
      SlideDirection direction, double ratio, bool isForward) {
    if (ratio >= 0 && preActionCount == 0) {
      return 0;
    } else if (ratio <= 0 && postActionCount == 0) {
      return 0;
    }

    return switch (direction) {
      SlideDirection.leftToRight ||
      SlideDirection.topToBottom =>
        isForward ? 1 : 0,
      SlideDirection.bottomToTop ||
      SlideDirection.rightToLeft =>
        isForward ? -1 : 0,
      SlideDirection.idle => 0,
    };
  }

  double getDragExtent(Axis axis, double ratio) {
    final mainAxis = axis == Axis.horizontal ? size.width : size.height;
    return mainAxis * ratio;
  }
}
