import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tips/slidable/action_motion.dart';
import 'package:flutter_tips/slidable/action_render.dart';

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

class SlideActionPanel<T extends Widget> extends MultiChildRenderObjectWidget {
  final ActionLayout actionLayout;
  final double slidePercent;
  final List<T> actions;

  const SlideActionPanel({
    Key? key,
    required this.actionLayout,
    required this.actions,
    this.slidePercent = 0.0,
  }) : super(
          key: key,
          children: actions,
        );

  @override
  RenderSlideAction createRenderObject(BuildContext context) {
    return RenderSlideAction(
      actionLayout: actionLayout,
      slidePercent: slidePercent,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSlideAction renderObject) {
    renderObject
      ..actionLayout = actionLayout
      ..slidePercent = slidePercent;
  }
}
