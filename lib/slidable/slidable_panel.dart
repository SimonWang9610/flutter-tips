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
/// [preActionPanelBuilder] would be used to build the panel that contains actions before the main child.
/// if [preActionPanelBuilder] is null, the panel cannot slide to show the pre actions.
///
/// [postActionPanelBuilder] would be used to build the panel that contains actions after the main child.
/// if [postActionPanelBuilder] is null, the panel cannot slide to show the post actions.
///
/// [maxSlideThreshold] would be used to determine the max ratio of the panel that can slide, it should be in [0, 1]
///
/// each [SlideActionPanel] would be sized by the size of [child] * [maxSlideThreshold],
/// by doing so, the internal changes of [SlideActionPanel] would not affect the size of [child], for example,
/// expanding the action item would not invoke [RenderSlidable.performLayout]
class SlidablePanel extends StatefulWidget {
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
  State<SlidablePanel> createState() => _SlidablePanelState();

  static SlideController? of(BuildContext context) {
    final renderObject = context.findRenderObject() as RenderSlidable?;
    return renderObject?.controller;
  }
}

class _SlidablePanelState extends State<SlidablePanel> {
  bool get _hasPreActionPanel => widget.preActionPanel != null;
  bool get _hasPostActionPanel => widget.postActionPanel != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // todo: fix bug: when dragging starts, it may not follow the pointer position and jump to another position
      onHorizontalDragStart: (details) {
        print("onHorizontalDragStart: $_dragExtent");
      },
      onHorizontalDragUpdate:
          widget.axis == Axis.horizontal ? _onDragUpdate : null,
      onVerticalDragUpdate: widget.axis == Axis.vertical ? _onDragUpdate : null,
      onHorizontalDragEnd: _onDragEnd,
      onVerticalDragEnd: _onDragEnd,
      child: _SlidablePanel(
        controller: widget.controller,
        axis: widget.axis,
        maxSlideThreshold: widget.maxSlideThreshold,
        children: [
          if (_hasPreActionPanel) widget.preActionPanel!,
          widget.child,
          if (_hasPostActionPanel) widget.postActionPanel!,
        ],
      ),
    );
  }

  double _dragExtent = 0.0;
  bool _isForward = false;

  void _onDragUpdate(DragUpdateDetails details) {
    final shift =
        widget.axis == Axis.horizontal ? details.delta.dx : details.delta.dy;

    _isForward = _dragExtent * shift > 0;
    _dragExtent += shift;
    widget.controller.slideTo(_dragExtent);
  }

  void _onDragEnd(DragEndDetails details) async {
    final dragExtent = await widget.controller.toggle(
      isForward: _isForward,
    );

    print("onDragEnd: $dragExtent");

    _dragExtent = dragExtent ?? 0;

    _isForward = false;
  }
}
