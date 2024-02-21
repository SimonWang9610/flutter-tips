import 'package:flutter/rendering.dart';
import 'package:flutter_tips/onscreen/background.dart';
import 'package:flutter_tips/onscreen/widget.dart';
import 'package:flutter_tips/onscreen/painter.dart';

class RenderOnscreen extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, OnscreenBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, OnscreenBoxData>,
        DebugOverflowIndicatorMixin {
  RenderOnscreen({
    required OnscreenPadding padding,
    List<RenderBox>? children,
    OnscreenBackgroundPainter? backgroundPainter,
    OnscreenFocusNode? focusNode,
    Size? preferredSize,
  })  : _padding = padding,
        _backgroundPainter = backgroundPainter,
        _focusNode = focusNode,
        _preferredSize = preferredSize,
        super() {
    addAll(children);
  }

  OnscreenBackgroundPainter? _backgroundPainter;
  OnscreenBackgroundPainter? get backgroundPainter => _backgroundPainter;
  set backgroundPainter(OnscreenBackgroundPainter? value) {
    if (_backgroundPainter == value) return;

    final old = _backgroundPainter;
    _backgroundPainter = value;

    if (old == null || (_backgroundPainter?.shouldRepaint(old) ?? false)) {
      markNeedsPaint();
    }
  }

  OnscreenFocusNode? _focusNode;
  OnscreenFocusNode? get focusNode => _focusNode;
  set focusNode(OnscreenFocusNode? value) {
    if (_focusNode == value) return;
    final old = _focusNode;
    _focusNode = value;

    if (attached) {
      old?.removeListener(markNeedsPaint);
      _focusNode?.addListener(markNeedsPaint);
    }

    if (old == null || (_focusNode?.shouldRepaint(old) ?? false)) {
      markNeedsPaint();
    }
  }

  OnscreenPadding _padding;
  OnscreenPadding get padding => _padding;
  set padding(OnscreenPadding value) {
    if (_padding == value) return;
    _padding = value;
    markNeedsLayout();
  }

  Size? _preferredSize;
  Size? get preferredSize => _preferredSize;
  set preferredSize(Size? value) {
    if (_preferredSize == value) return;
    _preferredSize = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! OnscreenBoxData) {
      child.parentData = OnscreenBoxData();
    }
  }

  final Map<OnscreenPosition, PositionScale> _scales = {};

  @override
  void performLayout() {
    assert(preferredSize != null ||
        constraints.hasBoundedWidth && constraints.hasBoundedHeight);

    _scales.clear();

    if (preferredSize != null) {
      size = constraints.constrain(preferredSize!);
    } else {
      size = constraints.biggest;
    }

    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as OnscreenBoxData;

      assert(parentData.position != null,
          "Widget must be wrapped by OnscreenElementWidget to know its position");

      final scale = PositionScale.fromPadding(padding, parentData.position!);

      parentData.offset = scale.getTopLeft(size);
      child.layout(
        BoxConstraints(
          maxWidth: scale.width * size.width,
          maxHeight: scale.height * size.height,
        ),
        parentUsesSize: false,
      );

      assert(!_scales.containsKey(parentData.position!),
          "Duplicate position: ${parentData.position}. Each child must have a unique position");

      _scales[parentData.position!] = scale;
      child = parentData.nextSibling;
    }
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_backgroundPainter != null) {
      _backgroundPainter!.paint(context.canvas, size, padding);
    }

    defaultPaint(context, offset);

    if (focusNode != null && _scales.containsKey(focusNode!.focusedPosition)) {
      final scale = _scales[focusNode!.focusedPosition!]!;

      focusNode!.paint(context.canvas, scale.getScaleSize(size),
          scale.getTopLeft(size) + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _focusNode?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _focusNode?.removeListener(markNeedsPaint);
    super.detach();
  }
}

class PositionScale {
  final double originX;
  final double originY;
  final double width;
  final double height;

  const PositionScale({
    required this.originX,
    required this.originY,
    required this.width,
    required this.height,
  });

  Offset getTopLeft(Size size) {
    return Offset(originX * size.width, originY * size.height);
  }

  Size getScaleSize(Size size) {
    return Size(width * size.width, height * size.height);
  }

  BoxConstraints getConstraints(Size size) {
    return BoxConstraints(
      maxWidth: width * size.width,
      maxHeight: height * size.height,
    );
  }

  factory PositionScale.fromPadding(
      OnscreenPadding padding, OnscreenPosition position) {
    return switch (position) {
      OnscreenPosition.topLeft => PositionScale(
          originX: 0,
          originY: 0,
          width: padding.left,
          height: padding.top,
        ),
      OnscreenPosition.topCenter => PositionScale(
          originX: padding.left,
          originY: 0,
          width: padding.centerX,
          height: padding.top,
        ),
      OnscreenPosition.topRight => PositionScale(
          originX: 1 - padding.right,
          originY: 0,
          width: padding.right,
          height: padding.top,
        ),
      OnscreenPosition.centerLeft => PositionScale(
          originX: 0,
          originY: padding.top,
          width: padding.left,
          height: padding.centerY,
        ),
      OnscreenPosition.center => PositionScale(
          originX: padding.left,
          originY: padding.top,
          width: padding.centerX,
          height: padding.centerY,
        ),
      OnscreenPosition.centerRight => PositionScale(
          originX: 1 - padding.right,
          originY: padding.top,
          width: padding.right,
          height: padding.centerY,
        ),
      OnscreenPosition.bottomLeft => PositionScale(
          originX: 0,
          originY: 1 - padding.bottom,
          width: padding.left,
          height: padding.bottom,
        ),
      OnscreenPosition.bottomCenter => PositionScale(
          originX: padding.left,
          originY: 1 - padding.bottom,
          width: padding.centerX,
          height: padding.bottom,
        ),
      OnscreenPosition.bottomRight => PositionScale(
          originX: 1 - padding.right,
          originY: 1 - padding.bottom,
          width: padding.right,
          height: padding.bottom,
        ),
    };
  }
}
