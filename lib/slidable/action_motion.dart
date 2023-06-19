import 'package:flutter/widgets.dart';
import 'package:flutter_tips/slidable/action_render.dart';
import 'package:flutter_tips/slidable/models.dart';

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

abstract class BaseActionLayout {
  final ActionPosition position;
  final ActionMotion motion;
  BaseActionLayout({
    required this.position,
    required this.motion,
  });

  void layout(
    RenderBox child,
    Size size,
    int childCount, {
    double ratio = 1.0,
    required Axis axis,
  }) {
    assert(!size.isEmpty && childCount > 0);

    final sizedConstraints = getSizedConstraints(
      size: size,
      axis: axis,
      childCount: childCount,
    );

    RenderBox? current = child;

    int index = 0;

    while (current != null) {
      current.layout(sizedConstraints.constraints[index], parentUsesSize: true);
      final parentData = current.parentData as SlideActionBoxData;

      parentData.offset = getRelativeOffset(
        sizedConstraints: sizedConstraints,
        index: index,
        ratio: ratio,
      );
      current = parentData.nextSibling;
      index++;
    }
  }

  SizedConstraints getSizedConstraints({
    required Size size,
    required Axis axis,
    required int childCount,
  });

  Offset getRelativeOffset({
    required SizedConstraints sizedConstraints,
    required int index,
    required double ratio,
  });
}

class SpaceEvenlyLayout extends BaseActionLayout {
  SpaceEvenlyLayout({
    required super.motion,
    required super.position,
  });

  @override
  SizedConstraints getSizedConstraints({
    required Size size,
    required Axis axis,
    required int childCount,
  }) {
    assert(!size.isEmpty && childCount > 0);

    final childConstraints = switch (axis) {
      Axis.horizontal => BoxConstraints.tightFor(
          width: size.width / childCount,
          height: size.height,
        ),
      Axis.vertical => BoxConstraints.tightFor(
          width: size.width,
          height: size.height / childCount,
        ),
    };

    return SizedConstraints(
      size: size,
      axis: axis,
      constraints: List.generate(childCount, (index) => childConstraints),
    );
  }

  @override
  Offset getRelativeOffset({
    required SizedConstraints sizedConstraints,
    required int index,
    required double ratio,
  }) {
    assert(ratio >= 0 && ratio <= 1);
    final shift = sizedConstraints.averageShift * index.toDouble();

    return switch (motion) {
      ActionMotion.stretch || ActionMotion.drawer => shift * ratio,
      ActionMotion.behind => shift,
      ActionMotion.scroll => shift + sizedConstraints.totalShift * (ratio - 1),
    };
  }
}

class FlexLayout extends BaseActionLayout {
  final List<int> flexes;
  FlexLayout({
    required super.motion,
    required super.position,
    this.flexes = const [],
  });

  @override
  void layout(
    RenderBox child,
    Size size,
    int childCount, {
    double ratio = 1.0,
    required Axis axis,
  }) {
    assert(!size.isEmpty && childCount > 0);

    RenderBox? current = child;

    if (flexes.isEmpty || flexes.length != childCount) {
      flexes.clear();
      while (current != null) {
        final parentData = current.parentData as SlideActionBoxData;
        final flex = parentData.flex ?? 0;
        flexes.add(flex);
        current = parentData.nextSibling;
      }
    }

    super.layout(
      child,
      size,
      childCount,
      ratio: ratio,
      axis: axis,
    );
  }

  @override
  SizedConstraints getSizedConstraints({
    required Size size,
    required Axis axis,
    required int childCount,
  }) {
    final totalFlex = flexes.reduce((a, b) => a + b);

    assert(childCount == flexes.length && totalFlex > 0,
        "At least one action widget should have a flex value greater than 0");

    final spaceForEachFlex = switch (axis) {
      Axis.horizontal => size.width / flexes.reduce((a, b) => a + b),
      Axis.vertical => size.height / flexes.reduce((a, b) => a + b),
    };

    final constraints = flexes
        .map((flex) => switch (axis) {
              Axis.horizontal => BoxConstraints.tightFor(
                  width: spaceForEachFlex * flex,
                  height: size.height,
                ),
              Axis.vertical => BoxConstraints.tightFor(
                  width: size.width,
                  height: spaceForEachFlex * flex,
                ),
            })
        .toList();

    return SizedConstraints(
      size: size,
      axis: axis,
      constraints: constraints,
    );
  }

  Offset _previousShift = Offset.zero;

  @override
  Offset getRelativeOffset({
    required SizedConstraints sizedConstraints,
    required int index,
    required double ratio,
  }) {
    assert(ratio >= 0 && ratio <= 1);
    final shift = _previousShift;

    switch (motion) {
      case ActionMotion.stretch || ActionMotion.drawer:
        _previousShift +=
            sizedConstraints.getShiftFromConstraints(index) * ratio;
        break;
      case ActionMotion.behind || ActionMotion.scroll:
        _previousShift += sizedConstraints.getShiftFromConstraints(index);
        break;
    }

    return shift +
        (motion == ActionMotion.scroll
            ? sizedConstraints.totalShift * (ratio - 1)
            : Offset.zero);
  }
}

enum ActionMotion {
  behind,
  stretch,
  drawer,
  scroll,
}

enum ActionAlignment {
  spaceEvenly,
  flex,
}

class ActionLayout {
  final ActionMotion motion;
  final ActionAlignment alignment;

  const ActionLayout({
    required this.motion,
    required this.alignment,
  });

  BaseActionLayout buildDelegate(ActionPosition position) {
    switch (alignment) {
      case ActionAlignment.spaceEvenly:
        return SpaceEvenlyLayout(
          motion: motion,
          position: position,
        );
      case ActionAlignment.flex:
        return FlexLayout(
          motion: motion,
          position: position,
        );
    }
  }

  factory ActionLayout.spaceEvenly(
          [ActionMotion motion = ActionMotion.behind]) =>
      ActionLayout(
        motion: motion,
        alignment: ActionAlignment.spaceEvenly,
      );

  factory ActionLayout.flex([ActionMotion motion = ActionMotion.behind]) =>
      ActionLayout(
        motion: motion,
        alignment: ActionAlignment.flex,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionLayout &&
          runtimeType == other.runtimeType &&
          motion == other.motion &&
          alignment == other.alignment;

  @override
  int get hashCode => motion.hashCode ^ alignment.hashCode;

  @override
  String toString() {
    return 'ActionLayout{motion: $motion, alignment: $alignment}';
  }
}
