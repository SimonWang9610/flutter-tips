import 'dart:math';
import 'package:flutter/rendering.dart';

import 'node.dart';
import 'tree_edge_painter.dart';
import 'tree_layout_delegate.dart';

abstract class RenderTreeViewBase<
        T extends BaseNode,
        P extends TreeViewEdgePainter,
        L extends ContainerLayer> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData>,
        DebugOverflowIndicatorMixin {
  T _root;
  TreeViewLayoutDelegate _layoutDelegate;
  P _edgePainter;

  final LayerHandle<L> _layer = LayerHandle<L>();

  RenderTreeViewBase({
    required T root,
    required P edgePainter,
    required TreeViewLayoutDelegate layoutDelegate,
    List<RenderBox>? children,
  })  : _root = root,
        _layoutDelegate = layoutDelegate,
        _edgePainter = edgePainter {
    addAll(children);
  }

  /// TODO: optimize checking if two trees are identical
  T get root => _root;
  set root(T value) {
    if (!_root.isSameTree(value)) {
      _root = value;
      markNeedsLayout();
    }
  }

  TreeViewLayoutDelegate get layoutDelegate => _layoutDelegate;
  set layoutDelegate(TreeViewLayoutDelegate value) {
    if (_layoutDelegate == value) {
      return;
    }

    final TreeViewLayoutDelegate oldDelegate = _layoutDelegate;
    if (oldDelegate.runtimeType != value.runtimeType ||
        value.shouldRelayout(oldDelegate)) {
      markNeedsLayout();
    }
    _layoutDelegate = value;

    if (attached) {
      oldDelegate.removeListener(markNeedsLayout);
      _layoutDelegate.addListener(markNeedsLayout);
    }
  }

  P get edgePainter => _edgePainter;
  set edgePainter(P value) {
    if (_edgePainter == value) {
      return;
    }

    final TreeViewEdgePainter oldPainter = _edgePainter;

    if (oldPainter.runtimeType != value.runtimeType ||
        value.shouldRepaint(oldPainter)) {
      markNeedsPaint();
    }
    _edgePainter = value;

    if (attached) {
      oldPainter.removeListener(markNeedsPaint);
      _edgePainter.addListener(markNeedsPaint);
    }
  }

  /// call [BoxConstraints.constrain] to ensure [size] can pass [debugAssertDoesMeetConstraints]
  @override
  void performLayout() {
    final actualSize = _layoutDelegate.layout(constraints.loosen(), firstChild);

    size = constraints.constrain(actualSize);
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeBoxData) {
      child.parentData = NodeBoxData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _layoutDelegate.addListener(markNeedsLayout);
    _edgePainter.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _layoutDelegate.removeListener(markNeedsLayout);
    _edgePainter.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _layer.layer = null;
    _layoutDelegate.dispose();
    _edgePainter.dispose();
    super.dispose();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BaseNode>('root', root));
    properties.add(DiagnosticsProperty<TreeViewLayoutDelegate>(
        'layoutDelegate', layoutDelegate));
    properties.add(
        DiagnosticsProperty<TreeViewEdgePainter>('edgePainter', edgePainter));
  }
}

class RenderClipTreeView<T extends BaseNode>
    extends RenderTreeViewBase<T, ClipEdgePainter, ClipRectLayer> {
  RenderClipTreeView({
    required super.root,
    required super.edgePainter,
    required super.layoutDelegate,
    super.children,
  });

  bool _hasOverflow = false;

  @override
  void performLayout() {
    super.performLayout();

    if (size.width < root.normalizedSize.width ||
        size.height < root.normalizedSize.height) {
      _hasOverflow = true;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _edgePainter.paintEdges(root, context.canvas, offset);

    if (!_hasOverflow) {
      defaultPaint(context, offset);
      return;
    }

    if (size.isEmpty) {
      return;
    }

    _layer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
      clipBehavior: _edgePainter.clipBehavior,
      oldLayer: _layer.layer,
    );

    assert(() {
      // Only set this if it's null to save work. It gets reset to null if the
      // _direction changes.
      final List<DiagnosticsNode> debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
          'The edge of the $runtimeType that is overflowing has been marked '
          'in the rendering with a yellow and black striped pattern. This is '
          'usually caused by the contents being too big for the $runtimeType. '
          'The required size is ${root.normalizedSize}, but the maximum size cannot be greater than: ${constraints.biggest}.',
        ),
        ErrorHint(
          'This is considered an error condition because it indicates that there '
          'is content that cannot be seen. If the content is legitimately bigger '
          'than the available space, consider clipping it with a ClipRect widget.',
        ),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.

      final overflowChildRect = Rect.fromLTWH(
          0.0, 0.0, root.normalizedSize.width, root.normalizedSize.height);
      paintOverflowIndicator(
          context, offset, Offset.zero & size, overflowChildRect,
          overflowHints: debugOverflowHints);
      return true;
    }());
  }
}

class RenderTransformTreeView<T extends BaseNode>
    extends RenderTreeViewBase<T, TransformEdgePainter, TransformLayer> {
  RenderTransformTreeView({
    required super.root,
    required super.edgePainter,
    required super.layoutDelegate,
    super.children,
    this.transformHitTests = true,
    bool autoScale = true,
    Matrix4? transform,
  }) : _autoScale = autoScale;

  Matrix4? _autoTransform;
  bool _autoScale;

  bool transformHitTests;

  set autoScale(bool value) {
    if (_autoScale != value) {
      _autoScale = value;
      markNeedsLayout();
    }
  }

  Matrix4? get _effectiveTransform {
    if (_edgePainter.transform != null && _autoTransform != null) {
      return _autoTransform!.multiplied(_edgePainter.transform!);
    } else if (_autoTransform != null) {
      return _autoTransform;
    } else {
      return _edgePainter.transform;
    }
  }

  @override
  void performLayout() {
    print("render transform tree view layout");
    super.performLayout();

    final scaleX = min(size.width / root.normalizedSize.width, 1.0);
    final scaleY = min(size.height / root.normalizedSize.height, 1.0);

    if (_autoScale && (scaleX < 1.0 || scaleY < 1.0)) {
      _autoTransform = Matrix4.identity().scaled(scaleX, scaleY);
    } else {
      _autoTransform = null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Matrix4? transform = _effectiveTransform;

    if (transform == null) {
      _paintWithEdges(context, offset);
      _layer.layer = null;
      return;
    } else {
      final Offset? childOffset = MatrixUtils.getAsTranslation(transform);

      if (childOffset == null) {
        final double det = transform.determinant();
        if (det == 0 || !det.isFinite) {
          _layer.layer = null;
          return;
        }

        _layer.layer = context.pushTransform(
          needsCompositing,
          offset,
          transform,
          _paintWithEdges,
          oldLayer: _layer.layer,
        );
      } else {
        _paintWithEdges(context, offset + childOffset);
        _layer.layer = null;
      }
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_effectiveTransform!);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // RenderTransform objects don't check if they are
    // themselves hit, because it's confusing to think about
    // how the untransformed size and the child's transformed
    // position interact.
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_effectiveTransform == null) {
      return super.hitTestChildren(result, position: position);
    } else {
      return result.addWithPaintTransform(
        transform: transformHitTests ? _effectiveTransform : null,
        position: position,
        hitTest: (BoxHitTestResult result, Offset position) {
          return super.hitTestChildren(result, position: position);
        },
      );
    }
  }

  void _paintWithEdges(PaintingContext context, Offset offset) {
    _edgePainter.paintEdges(root, context.canvas, offset);
    defaultPaint(context, offset);
    return;
  }
}
