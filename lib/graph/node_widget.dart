import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'node.dart';
import 'tree_view.dart';

/// use [NodeBoxData] to allow [TreeView] to access the [BaseNode] associated with the widget
class NodeWidget<T extends BaseNode> extends ParentDataWidget<NodeBoxData> {
  final T node;

  const NodeWidget({
    super.key,
    required this.node,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is NodeBoxData);

    final NodeBoxData parentData = renderObject.parentData! as NodeBoxData;

    bool needsLayout = false;

    if (parentData.node != node) {
      parentData.node = node;
      needsLayout = true;
    }

    if (parentData.node?.parent != node.parent) {
      parentData.node = node;
      needsLayout = true;
    }

    if (needsLayout) {}
    final AbstractNode? targetParent = renderObject.parent;

    if (targetParent is RenderObject) {
      targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => TreeView;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BaseNode>('node', node));
  }
}
