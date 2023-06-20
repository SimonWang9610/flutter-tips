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

enum ActionMotion {
  behind,
  stretch,
  drawer,
  scroll,
}

/// [spaceEvenly] layout is the default layout of [SlideActionPanel],
/// and all action items would be laid out evenly in the [SlideActionPanel]
/// [flex] layout is similar to the [spaceEvenly] layout, but the action items would be laid out according to their flex values
enum ActionAlignment {
  spaceEvenly,
  flex,
}

class LayoutSize {
  final Size size;
  final bool hasPreAction;
  final bool hasPostAction;
  final Axis axis;
  final double maxSlideThreshold;

  const LayoutSize({
    required this.size,
    required this.hasPreAction,
    required this.hasPostAction,
    required this.axis,
    required this.maxSlideThreshold,
  });

  /// if no action, return null
  /// by doing so, we could disable sliding if no actions along the [axis]
  double? getRatio(
    double dragExtent,
  ) {
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

  double getDragExtent(double ratio) {
    final mainAxis = axis == Axis.horizontal
        ? size.width * maxSlideThreshold
        : size.height * maxSlideThreshold;
    return mainAxis * ratio;
  }

  double? getOpenTarget(ActionPosition position) {
    if (position == ActionPosition.pre && !hasPreAction) {
      return null;
    } else if (position == ActionPosition.post && !hasPostAction) {
      return null;
    }

    return switch (position) {
      ActionPosition.pre => 1,
      ActionPosition.post => -1,
    };
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
