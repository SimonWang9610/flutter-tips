import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter_tips/slidable/render.dart';

class SlideActionBoxData extends ContainerBoxParentData<RenderBox> {
  bool isActionPanel = false;
}

class SlideActionWidget extends ParentDataWidget<SlideActionBoxData> {
  final bool isActionPanel;
  const SlideActionWidget({
    super.key,
    this.isActionPanel = true,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is SlideActionBoxData);
    final parentData = renderObject.parentData as SlideActionBoxData;
    if (parentData.isActionPanel != isActionPanel) {
      parentData.isActionPanel = isActionPanel;
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) {
        targetParent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => SlidablePanel;
}

class SlidablePanel extends MultiChildRenderObjectWidget {
  final Axis axis;
  final SlideDirection direction;
  final SlideController controller;
  final double visibleThreshold;
  final List<Widget> actions;

  const SlidablePanel({
    Key? key,
    this.axis = Axis.horizontal,
    this.direction = SlideDirection.leftToRight,
    required this.controller,
    this.visibleThreshold = 0.5,
    required this.actions,
  }) : super(key: key, children: actions);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSlidable(
      axis: axis,
      direction: direction,
      controller: controller,
      visibleThreshold: visibleThreshold,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSlidable renderObject) {
    renderObject
      ..axis = axis
      ..direction = direction
      ..controller = controller
      ..visibleThreshold = visibleThreshold;
  }
}
