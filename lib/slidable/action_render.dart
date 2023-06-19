import 'package:flutter/rendering.dart';
import 'package:flutter_tips/slidable/action_item_render.dart';
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
    ActionItemExpander? expander,
    double slidePercent = 0.0,
  })  : _actionLayout = actionLayout,
        _slidePercent = slidePercent {
    addAll(children);
  }

  ActionItemExpander? _expander;
  ActionItemExpander? get expander => _expander;
  set expander(ActionItemExpander? value) {
    if (_expander != value) {
      final old = _expander;
      _expander = value;

      if (attached) {
        old?.removeListener(_markNeedsLayoutIfNeeded);
        value?.addListener(_markNeedsLayoutIfNeeded);
      }
    }
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
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _expander?.addListener(_markNeedsLayoutIfNeeded);
  }

  @override
  void detach() {
    _expander?.removeListener(_markNeedsLayoutIfNeeded);
    super.detach();
  }

  void _markNeedsLayoutIfNeeded() {
    if (_expander != null && _expander!.index != null) {
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

    final layoutDelegate = _actionLayout.buildDelegate(
      position,
      expander: expander,
    );

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
