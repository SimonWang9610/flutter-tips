import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tips/slidable/action_motion.dart';
import 'package:flutter_tips/slidable/render.dart';

class SlideActionBoxData extends ContainerBoxParentData<RenderBox> {
  int? flex;
}

class RenderSlideAction extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, SlideActionBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, SlideActionBoxData> {
  RenderSlideAction({
    List<RenderBox>? children,
    required ActionLayout actionLayout,
    double slidePercent = 0.0,
  })  : _actionLayout = actionLayout,
        _slidePercent = slidePercent {
    addAll(children);
  }

  double _slidePercent;
  double get slidePercent => _slidePercent;
  set slidePercent(double value) {
    if (_slidePercent != value) {
      _slidePercent = value;
      markNeedsLayout();
    }
  }

  ActionLayout _actionLayout;
  ActionLayout get actionLayout => _actionLayout;
  set actionLayout(ActionLayout value) {
    if (_actionLayout != value) {
      _actionLayout = value;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! SlideActionBoxData) {
      child.parentData = SlideActionBoxData();
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    final child = firstChild;
    final position = (parentData as SlidableBoxData).position!;

    if (child == null || size.isEmpty) {
      // if (child == null) {
      //   _slidableRender.reportNoValidActions(position);
      // }
      return;
    }

    final layoutDelegate = _actionLayout.buildDelegate(position);

    layoutDelegate.layout(
      firstChild!,
      size,
      childCount,
      ratio: slidePercent,
      axis: _slideAxis,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;

    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  Axis get _slideAxis => _slidableRender.controller.axis;

  RenderSlidable get _slidableRender {
    RenderObject? parentNode = parent as RenderObject?;

    while (parentNode != null) {
      if (parentNode is RenderSlidable) {
        return parentNode;
      }

      parentNode = parentNode.parent as RenderObject?;
    }

    throw FlutterError(
        'RenderSlideAction must be a descendant of [RenderSlidable]');
  }
}
