import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tips/slidable/action_item_expander.dart';
import 'package:flutter_tips/slidable/action_layout_delegate.dart';
import 'package:flutter_tips/slidable/slide_action_render.dart';

/// By wrapping [child] using [ActionItem], you can specify the flex value of the child.
class ActionItem extends ParentDataWidget<SlideActionBoxData> {
  final int flex;
  const ActionItem({
    super.key,
    required this.flex,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is SlideActionBoxData);
    final parentData = renderObject.parentData as SlideActionBoxData;

    if (parentData.flex != flex) {
      parentData.flex = flex;

      final targetParent = renderObject.parent as RenderObject;
      targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => SlideActionPanel;
}

/// if [actionLayout] is aligned using [ActionAlignment.flex], [actions] could be wrapped in [ActionItem] to specify the flex value.
/// if [actions] are not wrapped in [ActionItem], each item would have a default flex value of 1, behaving like [ActionAlignment.spaceEvenly].
///
/// if [actionLayout] is aligned using [ActionAlignment.spaceEvenly],
/// each action item would have same width/height determined by [SlidablePanel.axis].
///
/// [expander] would be used to determine whether to expand the action item.
/// the expanded item would occupy the total space of [SlideActionPanel],
/// while other items would not be visible and not respond to pointer events.
///
/// if [actions] is empty, the [SlidablePanel] can still slide but no widget would be shown.
class SlideActionPanel<T extends Widget> extends MultiChildRenderObjectWidget {
  final ActionLayout actionLayout;
  final ValueListenable<double> slidePercent;
  final List<T> actions;
  final ActionController? controller;

  const SlideActionPanel({
    Key? key,
    required this.actionLayout,
    required this.actions,
    required this.slidePercent,
    this.controller,
  }) : super(
          key: key,
          children: actions,
        );

  @override
  RenderSlideAction createRenderObject(BuildContext context) {
    return RenderSlideAction(
      actionLayout: actionLayout,
      slidePercent: slidePercent,
      controller: controller,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSlideAction renderObject) {
    renderObject
      ..actionLayout = actionLayout
      ..slidePercent = slidePercent
      ..controller = controller;
  }
}
