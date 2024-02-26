import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tips/slidable/action_item_expander.dart';
import 'package:flutter_tips/slidable/action_layout_delegate.dart';
import 'package:flutter_tips/slidable/models.dart';
import 'package:flutter_tips/slidable/slidable_render.dart';

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
    required ValueListenable<double> slidePercent,
    ActionController? controller,
  })  : _actionLayout = actionLayout,
        _slidePercent = slidePercent,
        _controller = controller {
    addAll(children);
  }

  ActionController? _controller;
  ActionController? get controller => _controller;
  set controller(ActionController? value) {
    if (_controller != value) {
      final old = _controller;
      _controller = value;

      if (attached) {
        old?.removeListener(_markNeedsLayoutIfNeeded);
        _controller?.addListener(_markNeedsLayoutIfNeeded);
      }
    }
  }

  ValueListenable<double> _slidePercent;
  ValueListenable<double> get slidePercent => _slidePercent;
  set slidePercent(ValueListenable<double> value) {
    if (_slidePercent != value) {
      final old = _slidePercent;
      _slidePercent = value;

      if (attached) {
        old.removeListener(_markNeedsLayoutIfCorrectPosition);
        value.addListener(_markNeedsLayoutIfCorrectPosition);
      }
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
    _controller?.addListener(_markNeedsLayoutIfNeeded);
    _slidePercent.addListener(_markNeedsLayoutIfCorrectPosition);
  }

  @override
  void detach() {
    _controller?.removeListener(_markNeedsLayoutIfNeeded);
    _slidePercent.removeListener(_markNeedsLayoutIfCorrectPosition);
    super.detach();
  }

  void _markNeedsLayoutIfNeeded() {
    if (_controller != null && _controller!.index != null) {
      markNeedsLayout();
    }
  }

  void _markNeedsLayoutIfCorrectPosition() {
    final position = (parentData as SlidableBoxData).position;

    final shouldRelayout =
        position == ActionPosition.pre && slidePercent.value >= 0 ||
            position == ActionPosition.post && slidePercent.value <= 0;

    if (shouldRelayout) {
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

  // todo: report no valid action children
  @override
  void performLayout() {
    final child = firstChild;
    final position = (parentData as SlidableBoxData).position!;

    if (child == null || size.isEmpty) {
      return;
    }

    final layoutDelegate = _actionLayout.buildDelegate(
      position,
      controller: controller,
    );

    layoutDelegate.layout(
      firstChild!,
      size,
      childCount,
      ratio: slidePercent.value.abs(),
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

  Axis get _slideAxis => _slidableRender.axis;

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
