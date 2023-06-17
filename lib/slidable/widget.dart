import 'package:flutter/material.dart';
import 'package:flutter_tips/slidable/render.dart';
import 'controller.dart';

class _SlideAction extends ParentDataWidget<SlideActionBoxData> {
  final bool isActionPanel;
  const _SlideAction({
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
  Type get debugTypicalAncestorWidgetClass => _SlidablePanel;
}

class _SlidablePanel extends MultiChildRenderObjectWidget {
  final SlideController controller;
  final SlideActionLayoutDelegate layoutDelegate;
  const _SlidablePanel({
    required this.controller,
    required this.layoutDelegate,
    required super.children,
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSlidable(
      controller: controller,
      layoutDelegate: layoutDelegate,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSlidable renderObject) {
    renderObject
      ..layoutDelegate = layoutDelegate
      ..controller = controller;
  }
}

typedef SlideEndCallback = void Function(SlideController, bool);

class SlidablePanel extends StatefulWidget {
  final double threshold;
  final Widget child;
  final Axis axis;
  final SlideEndCallback? onSlideEnd;
  final List<Widget> preActions;
  final List<Widget> postActions;

  const SlidablePanel({
    super.key,
    required this.child,
    this.threshold = 0.4,
    this.axis = Axis.horizontal,
    this.preActions = const [],
    this.postActions = const [],
    this.onSlideEnd,
  });

  @override
  State<SlidablePanel> createState() => _SlidablePanelState();
}

class _SlidablePanelState extends State<SlidablePanel> {
  late final SlideController _slideController;

  final SlideActionLayoutDelegate _layoutDelegate = SlideActionLayoutDelegate();

  @override
  void initState() {
    super.initState();
    _slideController = SlideController(
      visibleThreshold: widget.threshold,
      axis: widget.axis,
    );
  }

  @override
  void didUpdateWidget(covariant SlidablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.threshold != widget.threshold) {
      _slideController.visibleThreshold = widget.threshold;
    }

    if (oldWidget.axis != widget.axis) {
      _slideController.axis = widget.axis;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preActions = widget.preActions.map((e) => _SlideAction(child: e));
    final postActions = widget.postActions.map((e) => _SlideAction(child: e));

    return GestureDetector(
      onHorizontalDragUpdate:
          _slideController.axis == Axis.horizontal ? _onDragUpdate : null,
      onVerticalDragUpdate:
          _slideController.axis == Axis.vertical ? _onDragUpdate : null,
      onHorizontalDragEnd: _onDragEnd,
      onVerticalDragEnd: _onDragEnd,
      child: _SlidablePanel(
        controller: _slideController,
        layoutDelegate: _layoutDelegate,
        children: [
          ...preActions,
          widget.child,
          ...postActions,
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

    _dragExtent = dragExtent ?? 0;

    _isForward = false;
  }
}
