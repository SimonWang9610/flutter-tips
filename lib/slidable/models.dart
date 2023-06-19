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

class LayoutSize {
  final Size size;
  final bool hasPreAction;
  final bool hasPostAction;

  const LayoutSize({
    required this.size,
    required this.hasPreAction,
    required this.hasPostAction,
  });

  /// if no action, return null
  /// by doing so, we could disable sliding if no actions along the [axis]
  double? getRatio(Axis axis, double dragExtent,
      {double maxSlideThreshold = 1.0}) {
    if ((dragExtent > 0 && !hasPreAction) ||
        (dragExtent < 0 && !hasPostAction)) {
      return null;
    }

    final mainAxis = axis == Axis.horizontal
        ? size.width * maxSlideThreshold
        : size.height * maxSlideThreshold;
    final ratio = dragExtent / mainAxis;
    return ratio;
  }

  /// [ratio] > 0  indicates we are sliding to see the pre actions
  /// [ratio] < 0  indicates we are sliding to see the post actions
  double getToggleTarget(
      SlideDirection direction, double ratio, bool isForward) {
    if (ratio >= 0 && !hasPreAction) {
      return 0;
    } else if (ratio <= 0 && !hasPostAction) {
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

  double getDragExtent(Axis axis, double ratio,
      {double maxSlideThreshold = 1.0}) {
    final mainAxis = axis == Axis.horizontal
        ? size.width * maxSlideThreshold
        : size.height * maxSlideThreshold;
    return mainAxis * ratio;
  }
}

class SizedConstraints {
  final Size size;
  final List<BoxConstraints> constraints;
  final Axis axis;

  const SizedConstraints({
    required this.size,
    required this.constraints,
    required this.axis,
  });

  Offset getShiftFromConstraints(int index) {
    final shift = switch (axis) {
      Axis.horizontal => Offset(
          constraints[index].maxWidth,
          0,
        ),
      Axis.vertical => Offset(
          0,
          constraints[index].maxHeight,
        ),
    };

    return shift;
  }

  Offset get averageShift {
    final shift = switch (axis) {
      Axis.horizontal => Offset(size.width / constraints.length, 0),
      Axis.vertical => Offset(0, size.height / constraints.length),
    };

    return shift;
  }

  Offset get totalShift {
    final shift = switch (axis) {
      Axis.horizontal => Offset(size.width, 0),
      Axis.vertical => Offset(0, size.height),
    };

    return shift;
  }
}
