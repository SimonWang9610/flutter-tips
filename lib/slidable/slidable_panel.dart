import 'package:flutter/material.dart';
import 'package:flutter_tips/slidable/action_item_expander.dart';
import 'package:flutter_tips/slidable/slidable_render.dart';
import 'controller.dart';

import 'slide_action_panel.dart';

class _SlidablePanel extends MultiChildRenderObjectWidget {
  final SlideController controller;
  const _SlidablePanel({
    required this.controller,
    required super.children,
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSlidable(controller: controller);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSlidable renderObject) {
    renderObject.controller = controller;
  }
}

typedef SlideEndCallback = void Function(SlideController, bool);
typedef SlideActionPanelBuilder = SlideActionPanel Function(
    BuildContext, double, ActionItemExpander?);

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
  final SlideActionPanelBuilder? preActionPanelBuilder;
  final SlideActionPanelBuilder? postActionPanelBuilder;

  const SlidablePanel({
    super.key,
    required this.child,
    this.maxSlideThreshold = 0.6,
    this.axis = Axis.horizontal,
    this.preActionPanelBuilder,
    this.postActionPanelBuilder,
  });

  @override
  State<SlidablePanel> createState() => _SlidablePanelState();

  static SlideController? of(BuildContext context) {
    final renderObject = context.findRenderObject() as RenderSlidable?;
    return renderObject?.controller;
  }
}

class _SlidablePanelState extends State<SlidablePanel> {
  late final SlideController _slideController;

  final ActionItemExpander _preActionsExpander = ActionItemExpander();
  final ActionItemExpander _postActionsExpander = ActionItemExpander();

  @override
  void initState() {
    super.initState();
    _slideController = SlideController(
      maxSlideThreshold: widget.maxSlideThreshold,
      axis: widget.axis,
    );
  }

  @override
  void didUpdateWidget(covariant SlidablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.maxSlideThreshold != widget.maxSlideThreshold) {
      _slideController.maxSlideThreshold = widget.maxSlideThreshold;
    }

    if (oldWidget.axis != widget.axis) {
      _slideController.axis = widget.axis;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _preActionsExpander.dispose();
    _postActionsExpander.dispose();
    super.dispose();
  }

  bool get _hasPreActionPanel => widget.preActionPanelBuilder != null;
  bool get _hasPostActionPanel => widget.postActionPanelBuilder != null;

  @override
  Widget build(BuildContext context) {
    final preActionPanel = _hasPreActionPanel
        ? ValueListenableBuilder(
            valueListenable: _slideController.animationValue,
            builder: (BuildContext context, percent, _) =>
                widget.preActionPanelBuilder!.call(
              context,
              percent >= 0 ? percent : 0.0,
              _preActionsExpander,
            ),
          )
        : null;

    final postActionPanel = _hasPostActionPanel
        ? ValueListenableBuilder(
            valueListenable: _slideController.animationValue,
            builder: (BuildContext context, percent, _) =>
                widget.postActionPanelBuilder!.call(
              context,
              percent <= 0 ? percent.abs() : 0.0,
              _postActionsExpander,
            ),
          )
        : null;

    return GestureDetector(
      // todo: fix bug: when dragging starts, it may not follow the pointer position and jump to another position
      onHorizontalDragStart: (details) {
        print("onHorizontalDragStart: $_dragExtent");
      },
      onHorizontalDragUpdate:
          _slideController.axis == Axis.horizontal ? _onDragUpdate : null,
      onVerticalDragUpdate:
          _slideController.axis == Axis.vertical ? _onDragUpdate : null,
      onHorizontalDragEnd: _onDragEnd,
      onVerticalDragEnd: _onDragEnd,
      child: _SlidablePanel(
        controller: _slideController,
        children: [
          if (preActionPanel != null) preActionPanel,
          widget.child,
          if (postActionPanel != null) postActionPanel,
        ],
      ),
    );
  }

  double _dragExtent = 0.0;
  bool _isForward = false;

  void _onDragUpdate(DragUpdateDetails details) {
    final shift = _slideController.axis == Axis.horizontal
        ? details.delta.dx
        : details.delta.dy;

    _isForward = _dragExtent * shift > 0;
    _dragExtent += shift;
    _slideController.slideTo(_dragExtent);
  }

  void _onDragEnd(DragEndDetails details) async {
    final dragExtent = await _slideController.toggle(
      isForward: _isForward,
    );

    _preActionsExpander.reset();
    _postActionsExpander.reset();

    _dragExtent = dragExtent ?? 0;

    _isForward = false;
  }
}
