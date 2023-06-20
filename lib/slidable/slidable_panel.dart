import 'package:flutter/material.dart';
import 'package:flutter_tips/slidable/slidable_render.dart';
import 'controller.dart';

import 'slide_action_panel.dart';

class _SlidablePanel extends MultiChildRenderObjectWidget {
  final SlideController controller;
  final Axis axis;
  final double maxSlideThreshold;
  const _SlidablePanel({
    required this.controller,
    required super.children,
    required this.axis,
    required this.maxSlideThreshold,
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSlidable(
      controller: controller,
      axis: axis,
      maxSlideThreshold: maxSlideThreshold,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSlidable renderObject) {
    renderObject
      ..controller = controller
      ..axis = axis
      ..maxSlideThreshold = maxSlideThreshold;
  }
}

/// [SlidablePanel] is a widget that can slide to show actions.
/// [child] would be the main child of the panel.
///
/// [maxSlideThreshold] would be used to determine the max ratio of the panel that can slide, it should be in [0, 1]
///
/// each [SlideActionPanel] would be sized by the size of [child] * [maxSlideThreshold],
/// by doing so, the internal changes of [SlideActionPanel] would not affect the size of [child], for example,
/// expanding the action item would not invoke [RenderSlidable.performLayout]
class SlidablePanel extends StatelessWidget {
  final double maxSlideThreshold;
  final Widget child;
  final Axis axis;
  final SlideActionPanel? preActionPanel;
  final SlideActionPanel? postActionPanel;
  final SlideController controller;

  const SlidablePanel({
    super.key,
    required this.child,
    required this.controller,
    this.maxSlideThreshold = 0.6,
    this.axis = Axis.horizontal,
    this.preActionPanel,
    this.postActionPanel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate:
          axis == Axis.horizontal ? controller.onDragUpdate : null,
      onVerticalDragUpdate:
          axis == Axis.vertical ? controller.onDragUpdate : null,
      onHorizontalDragEnd:
          axis == Axis.horizontal ? controller.onDragEnd : null,
      onVerticalDragEnd: axis == Axis.vertical ? controller.onDragEnd : null,
      child: _SlidablePanel(
        controller: controller,
        axis: axis,
        maxSlideThreshold: maxSlideThreshold,
        children: [
          if (preActionPanel != null) preActionPanel!,
          child,
          if (postActionPanel != null) postActionPanel!,
        ],
      ),
    );
  }

  static SlideController? of(BuildContext context) {
    final renderObject = context.findRenderObject() as RenderSlidable?;
    return renderObject?.controller;
  }
}
