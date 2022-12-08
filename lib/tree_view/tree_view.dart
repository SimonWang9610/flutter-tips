import 'package:flutter/material.dart';

import 'node.dart';
import 'tree_edge_painter.dart';
import 'tree_layout_delegate.dart';
import 'tree_view_render.dart';

/// [TreeView.clip] will create a tree view that can be clipped if overflowing and painting overflow bar in debug mode
/// [TreeView.transform] will create a tree view that can be scaled up and down, and also can scale down if overflowing
abstract class TreeView<T extends BaseNode, P extends TreeViewEdgePainter>
    extends MultiChildRenderObjectWidget {
  final T root;

  /// [RenderTreeViewBase] will use [layoutDelegate] to layout all node widgets
  /// if [TreeViewLayoutDelegate.layoutBuilder] is not provided, using the default layout builder
  final TreeViewLayoutDelegate layoutDelegate;

  /// if want to clip the overflow area when the actual size is over the given size, use [ClipEdgePainter]
  /// if want to scale the three view, use [TransformEdgePainter]
  /// customize how to connect nodes with their parent by providing [TreeViewEdgePainter.edgePainter] and [TreeViewEdgePainter.paint]
  /// if both are not provided, using the default setting instead
  final P edgePainter;

  TreeView({
    Key? key,
    required this.root,
    required NodeWidgetBuilder<T> nodeBuilder,
    required this.layoutDelegate,
    required this.edgePainter,
  }) : super(
          key: key,
          children: BaseNode.extractChildrenWidget(root, nodeBuilder),
        );

  @override
  RenderTreeViewBase createRenderObject(BuildContext context);

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderTreeViewBase renderObject);

  static Widget clip<T extends BaseNode>({
    Key? key,
    required T root,
    required ClipEdgePainter edgePainter,
    required TreeViewLayoutDelegate layoutDelegate,
    required NodeWidgetBuilder<T> nodeBuilder,
    Offset? delta,
  }) =>
      _ClipTreeView(
        key: key,
        root: root,
        nodeBuilder: nodeBuilder,
        layoutDelegate: layoutDelegate,
        edgePainter: edgePainter,
        delta: delta ?? Offset.zero,
      );

  static Widget transform<T extends BaseNode>({
    Key? key,
    required T root,
    required TransformEdgePainter edgePainter,
    required TreeViewLayoutDelegate layoutDelegate,
    required NodeWidgetBuilder<T> nodeBuilder,
    bool autoScale = true,
  }) =>
      _TransformTreeView(
        key: key,
        root: root,
        nodeBuilder: nodeBuilder,
        layoutDelegate: layoutDelegate,
        edgePainter: edgePainter,
        autoScale: autoScale,
      );
}

class _ClipTreeView<T extends BaseNode> extends TreeView<T, ClipEdgePainter> {
  final Offset delta;
  _ClipTreeView({
    super.key,
    required super.root,
    required super.nodeBuilder,
    required super.layoutDelegate,
    required super.edgePainter,
    this.delta = Offset.zero,
  });

  @override
  RenderClipTreeView createRenderObject(BuildContext context) {
    return RenderClipTreeView<T>(
      root: root,
      layoutDelegate: layoutDelegate,
      edgePainter: edgePainter,
      delta: delta,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderClipTreeView renderObject) {
    renderObject
      ..root = root
      ..layoutDelegate = layoutDelegate
      ..edgePainter = edgePainter
      ..delta = delta;
  }
}

class _TransformTreeView<T extends BaseNode>
    extends TreeView<T, TransformEdgePainter> {
  final bool transformHitTests;
  final bool autoScale;
  _TransformTreeView({
    super.key,
    required super.root,
    required super.nodeBuilder,
    required super.layoutDelegate,
    required super.edgePainter,
    this.autoScale = true,
    this.transformHitTests = true,
  });

  @override
  RenderTransformTreeView createRenderObject(BuildContext context) {
    return RenderTransformTreeView<T>(
      root: root,
      layoutDelegate: layoutDelegate,
      edgePainter: edgePainter,
      autoScale: autoScale,
      transformHitTests: transformHitTests,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderTransformTreeView renderObject) {
    renderObject
      ..root = root
      ..layoutDelegate = layoutDelegate
      ..edgePainter = edgePainter
      ..autoScale = autoScale
      ..transformHitTests = transformHitTests;
  }
}
