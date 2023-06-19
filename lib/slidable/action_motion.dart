import 'package:flutter/widgets.dart';
import 'package:flutter_tips/slidable/action_item_render.dart';
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
  final ActionItemExpander? expander;
  BaseActionLayout({
    required this.position,
    required this.motion,
    this.expander,
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

  // Offset getRelativeOffset({
  //   required SizedConstraints sizedConstraints,
  //   required int index,
  //   required double ratio,
  // });

  Offset _previousShift = Offset.zero;

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

  (double, double) get _itemExpanderRatios {
    final unExpandedRatio = 1 - (expander?.progress ?? 0.0);
    final expandedRatio = 1 + (expander?.progress ?? 0.0);

    return (expandedRatio, unExpandedRatio);
  }
}

class SpaceEvenlyLayout extends BaseActionLayout {
  SpaceEvenlyLayout({
    required super.motion,
    required super.position,
    super.expander,
  });

  @override
  SizedConstraints getSizedConstraints({
    required Size size,
    required Axis axis,
    required int childCount,
  }) {
    assert(!size.isEmpty && childCount > 0);

    final averageWidth = size.width / childCount;
    final averageHeight = size.height / childCount;

    // final childConstraints = switch (axis) {
    //   Axis.horizontal => BoxConstraints.tightFor(
    //       width: size.width / childCount,
    //       height: size.height,
    //     ),
    //   Axis.vertical => BoxConstraints.tightFor(
    //       width: size.width,
    //       height: size.height / childCount,
    //     ),
    // };
    final (expandedRatio, unExpandedRatio) = _itemExpanderRatios;

    final constraints = <BoxConstraints>[];

    for (int i = 0; i < childCount; i++) {
      final indexExpanded = expander?.index == i;

      final indexConstraints = switch (axis) {
        Axis.horizontal => BoxConstraints.tightFor(
            width: indexExpanded
                ? averageWidth * expandedRatio
                : averageWidth * unExpandedRatio,
            height: size.height,
          ),
        Axis.vertical => BoxConstraints.tightFor(
            width: size.width,
            height: indexExpanded
                ? averageHeight * expandedRatio
                : averageHeight * unExpandedRatio,
          ),
      };
      constraints.add(indexConstraints);
    }

    return SizedConstraints(
      size: size,
      axis: axis,
      constraints: constraints,
    );
  }

  // @override
  // Offset getRelativeOffset({
  //   required SizedConstraints sizedConstraints,
  //   required int index,
  //   required double ratio,
  // }) {
  //   assert(ratio >= 0 && ratio <= 1);
  //   final shift = sizedConstraints.averageShift * index.toDouble();

  //   return switch (motion) {
  //     ActionMotion.stretch || ActionMotion.drawer => shift * ratio,
  //     ActionMotion.behind => shift,
  //     ActionMotion.scroll => shift + sizedConstraints.totalShift * (ratio - 1),
  //   };
  // }
}

class FlexLayout extends BaseActionLayout {
  final List<int> flexes = [];
  FlexLayout({
    required super.motion,
    required super.position,
    super.expander,
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

    while (current != null) {
      final parentData = current.parentData as SlideActionBoxData;
      final flex = parentData.flex ?? 1;
      flexes.add(flex);
      current = parentData.nextSibling;
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

    final widthForEachFlex = size.width / totalFlex;
    final heightForEachFlex = size.height / totalFlex;

    final constraints = <BoxConstraints>[];
    final (expandedRatio, unExpandedRatio) = _itemExpanderRatios;

    double remainWidth = size.width;
    double remainHeight = size.height;

    for (int i = 0; i < childCount; i++) {
      final flex = flexes[i];
      final indexExpanded = expander?.index == i;

      switch (axis) {
        case Axis.horizontal:
          final indexConstraints = BoxConstraints.tightFor(
            width: indexExpanded
                ? widthForEachFlex * flex * expandedRatio
                : widthForEachFlex * flex * unExpandedRatio,
            height: size.height,
          );
          remainWidth -= indexConstraints.maxWidth;
          constraints.add(indexConstraints);
          break;

        case Axis.vertical:
          final indexConstraints = BoxConstraints.tightFor(
            width: size.width,
            height: indexExpanded
                ? heightForEachFlex * flex * expandedRatio
                : heightForEachFlex * flex * unExpandedRatio,
          );
          remainHeight -= indexConstraints.maxHeight;
          constraints.add(indexConstraints);
          break;
      }
    }

    if (expander?.index != null) {
      final index = expander!.index!;
      final indexConstraints = constraints[index];
      switch (axis) {
        case Axis.horizontal:
          constraints[index] = BoxConstraints.tightFor(
            width: indexConstraints.maxWidth + remainWidth,
            height: indexConstraints.maxHeight,
          );
          break;
        case Axis.vertical:
          constraints[index] = BoxConstraints.tightFor(
            width: indexConstraints.maxWidth,
            height: indexConstraints.maxHeight + remainHeight,
          );
          break;
      }
    }

    return SizedConstraints(
      size: size,
      axis: axis,
      constraints: constraints,
    );
  }

  // Offset _previousShift = Offset.zero;

  // @override
  // Offset getRelativeOffset({
  //   required SizedConstraints sizedConstraints,
  //   required int index,
  //   required double ratio,
  // }) {
  //   assert(ratio >= 0 && ratio <= 1);
  //   final shift = _previousShift;

  //   switch (motion) {
  //     case ActionMotion.stretch || ActionMotion.drawer:
  //       _previousShift +=
  //           sizedConstraints.getShiftFromConstraints(index) * ratio;
  //       break;
  //     case ActionMotion.behind || ActionMotion.scroll:
  //       _previousShift += sizedConstraints.getShiftFromConstraints(index);
  //       break;
  //   }

  //   return shift +
  //       (motion == ActionMotion.scroll
  //           ? sizedConstraints.totalShift * (ratio - 1)
  //           : Offset.zero);
  // }
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

  BaseActionLayout buildDelegate(
    ActionPosition position, {
    ActionItemExpander? expander,
  }) {
    switch (alignment) {
      case ActionAlignment.spaceEvenly:
        return SpaceEvenlyLayout(
          motion: motion,
          position: position,
          expander: expander,
        );
      case ActionAlignment.flex:
        return FlexLayout(
          motion: motion,
          position: position,
          expander: expander,
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
