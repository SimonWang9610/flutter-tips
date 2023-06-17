import 'package:flutter/material.dart';
import 'package:flutter_tips/slidable/render.dart';
import 'controller.dart';

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

class SlidablePanel extends StatefulWidget {
  final Widget child;
  final List<Widget> preActions;
  final List<Widget> postActions;
  const SlidablePanel({
    super.key,
    required this.child,
    this.preActions = const [],
    this.postActions = const [],
  });

  @override
  State<SlidablePanel> createState() => _SlidablePanelState();
}

class _SlidablePanelState extends State<SlidablePanel> {
  final SlideController _slideController =
      SlideController(visibleThreshold: 0.4);

  final SlideActionLayoutDelegate _layoutDelegate = SlideActionLayoutDelegate();

  @override
  void dispose() {
    _slideController.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SlidablePanel oldWidget) {
    print("didUpdateWidget");
    super.didUpdateWidget(oldWidget);
    _slideController.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final preActions =
        widget.preActions.map((e) => SlideActionWidget(child: e));
    final postActions =
        widget.postActions.map((e) => SlideActionWidget(child: e));

    return GestureDetector(
      onHorizontalDragUpdate:
          _slideController.axis == Axis.horizontal ? _onDragUpdate : null,
      onVerticalDragUpdate:
          _slideController.axis == Axis.vertical ? _onVerticalDragUpdate : null,
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

  void _onDragUpdate(DragUpdateDetails details) {
    _dragExtent += details.delta.dx;
    _slideController.slideTo(_dragExtent);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragExtent += details.delta.dy;
    _slideController.slideTo(_dragExtent);
  }

  void _onDragEnd(DragEndDetails details) async {
    print("onDragEnd: velocity: ${details.velocity}");
    _dragExtent = await _slideController.toggle();
  }
}
