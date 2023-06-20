import 'package:flutter/widgets.dart';
import 'package:flutter_tips/slidable/action_item_expander.dart';
import 'package:flutter_tips/slidable/slide_action_render.dart';
import 'package:flutter_tips/slidable/models.dart';

abstract class BaseActionLayoutDelegate {
  final ActionPosition position;
  final ActionMotion motion;
  final ActionController? controller;
  BaseActionLayoutDelegate({
    required this.position,
    required this.motion,
    this.controller,
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

  /// If [controller] is not null, the [controller]'s index would be expanded to occupy the total space of the [SlideActionPanel]
  /// however, the [ActionItemcontroller.index] may not occupy the total space after expanded
  /// therefore, we should add the remained space to the [ActionItemcontroller.index] before expanding it
  /// currently, all action items are laid out using a tight [BoxConstraints]
  SizedConstraints getSizedConstraints({
    required Size size,
    required Axis axis,
    required int childCount,
  });

  Offset _previousShift = Offset.zero;

  /// [index]'s offset would be relative to the previous [index]'s offset
  /// currently, each action item is laid out using a tight [BoxConstraints]
  /// so [SizedConstraints.getShiftFromConstraints] is used to get the size of the previous action item
  /// for [ActionMotion.stretch] and [ActionMotion.drawer], the previous action item's size is multiplied by [ratio],
  /// which is changed by the [SlideController.animationValue]
  /// for [ActionMotion.behind], action items' origin do not change during animation,
  /// for [ActionMotion.scroll], action items' origin are translated during animation
  ///! different [ActionPosition] would translate differently based on its [ActionMotion]
  /// todo: to position action items based on its [ActionMotion] and [ActionPosition] when expanding
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

    final shouldChangeOrigin =
        (motion == ActionMotion.scroll && position == ActionPosition.pre) ||
            (motion == ActionMotion.behind && position == ActionPosition.post);

    return shift +
        (shouldChangeOrigin
            ? sizedConstraints.totalShift * (ratio - 1)
            : Offset.zero);
  }

  /// if [controller] is not null, the [controller]'s index would be expanded to occupy the total space of the [SlideActionPanel]
  /// the other action items would be compressed to empty during animation of the [controller]
  /// if [controller] is null, all action items would have the same ratio and be laid out normally
  (double, double) get _itemControllerRatios {
    final unExpandedRatio = 1 - (controller?.progress ?? 0.0);
    final expandedRatio = 1 + (controller?.progress ?? 0.0);

    return (expandedRatio, unExpandedRatio);
  }

  void _fillRemainSpace(
    List<BoxConstraints> constraints, {
    required Axis axis,
    double remainWidth = 0.0,
    double remainHeight = 0.0,
  }) {
    if (controller?.index != null) {
      final indexConstraints = constraints[controller!.index!];

      switch (axis) {
        case Axis.horizontal:
          constraints[controller!.index!] = BoxConstraints.tightFor(
            width: indexConstraints.maxWidth + remainWidth,
            height: indexConstraints.maxHeight,
          );
          break;
        case Axis.vertical:
          constraints[controller!.index!] = BoxConstraints.tightFor(
            width: indexConstraints.maxWidth,
            height: indexConstraints.maxHeight + remainHeight,
          );
          break;
      }
    }
  }
}

class SpaceEvenlyLayoutDelegate extends BaseActionLayoutDelegate {
  SpaceEvenlyLayoutDelegate({
    required super.motion,
    required super.position,
    super.controller,
  });

  /// If [controller] is not null, the [controller]'s index would be expanded to occupy the total space of the [SlideActionPanel]
  /// however, the [ActionItemcontroller.index] may not occupy the total space after expanded
  /// therefore, we should add the remained space to the [ActionItemcontroller.index] before expanding it
  /// currently, all action items are laid out using a tight [BoxConstraints]
  @override
  SizedConstraints getSizedConstraints({
    required Size size,
    required Axis axis,
    required int childCount,
  }) {
    assert(!size.isEmpty && childCount > 0);

    final averageWidth = size.width / childCount;
    final averageHeight = size.height / childCount;

    final (expandedRatio, unExpandedRatio) = _itemControllerRatios;

    final constraints = <BoxConstraints>[];

    double remainWidth = size.width;
    double remainHeight = size.height;

    for (int i = 0; i < childCount; i++) {
      final indexExpanded = controller?.index == i;

      switch (axis) {
        case Axis.horizontal:
          final indexConstraints = BoxConstraints.tightFor(
            width: indexExpanded
                ? averageWidth * expandedRatio
                : averageWidth * unExpandedRatio,
            height: size.height,
          );
          remainWidth -= indexConstraints.maxWidth;
          constraints.add(indexConstraints);
          break;
        case Axis.vertical:
          final indexConstraints = BoxConstraints.tightFor(
            width: size.width,
            height: indexExpanded
                ? averageHeight * expandedRatio
                : averageHeight * unExpandedRatio,
          );
          remainHeight -= indexConstraints.maxHeight;
          constraints.add(indexConstraints);
          break;
      }
    }

    _fillRemainSpace(
      constraints,
      axis: axis,
      remainWidth: remainWidth,
      remainHeight: remainHeight,
    );

    return SizedConstraints(
      size: size,
      axis: axis,
      constraints: constraints,
    );
  }
}

class FlexLayoutDelegate extends BaseActionLayoutDelegate {
  final List<int> flexes = [];
  FlexLayoutDelegate({
    required super.motion,
    required super.position,
    super.controller,
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
    flexes.clear();
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
    final (expandedRatio, unExpandedRatio) = _itemControllerRatios;

    double remainWidth = size.width;
    double remainHeight = size.height;

    for (int i = 0; i < childCount; i++) {
      final flex = flexes[i];
      final indexExpanded = controller?.index == i;

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

    _fillRemainSpace(
      constraints,
      axis: axis,
      remainHeight: remainHeight,
      remainWidth: remainWidth,
    );

    return SizedConstraints(
      size: size,
      axis: axis,
      constraints: constraints,
    );
  }
}

class ActionLayout {
  final ActionMotion motion;

  /// when using [ActionLayout.flex], the [SlideActionPanel.actions] would have a default flex value of 1,
  /// if the item widget is not wrapped by [ActionItem]
  final ActionAlignment alignment;

  const ActionLayout({
    required this.motion,
    required this.alignment,
  });

  BaseActionLayoutDelegate buildDelegate(
    ActionPosition position, {
    ActionController? controller,
  }) {
    switch (alignment) {
      case ActionAlignment.spaceEvenly:
        return SpaceEvenlyLayoutDelegate(
          motion: motion,
          position: position,
          controller: controller,
        );
      case ActionAlignment.flex:
        return FlexLayoutDelegate(
          motion: motion,
          position: position,
          controller: controller,
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
