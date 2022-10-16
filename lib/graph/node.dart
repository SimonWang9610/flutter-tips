import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/graph/node_widget.dart';
import 'package:flutter_tips/graph/tree_view.dart';

typedef NodeWidgetBuilder<T extends BaseNode> = Widget Function(T);

class BaseNode {
  static void _propagateDepthToDescendants(BaseNode child, int parentDepth) {
    child.depth = parentDepth + 1;

    for (final node in child._children) {
      _propagateDepthToDescendants(node, child.depth);
    }
  }

  static List<Widget> extractChildrenWidget(
      BaseNode root, NodeWidgetBuilder builder) {
    final List<Widget> widgets = [];

    widgets.add(
      NodeWidget(
        node: root,
        child: builder(root),
      ),
    );

    /// depth first recursion
    for (final node in root.children) {
      widgets.addAll(extractChildrenWidget(node, builder));
    }

    return widgets;
  }

  final String id;

  final List<BaseNode> _children = [];

  BaseNode? parent;
  int depth = 0;

  Size _size = Size.zero;

  /// the center position of the node widget
  Offset _position = Offset.zero;

  double get height => _size.height;
  double get width => _size.width;
  Offset get offset => _position - Alignment.center.alongSize(_size);

  set size(Size value) {
    _size = value;
  }

  BaseNode({required this.id});

  void addChild(BaseNode value, {BaseNode? after}) {
    assert(
        _children.fold(
            true, (previousValue, element) => element.id != value.id),
        "The new node id is not unique");

    if (after == null) {
      _children.add(value);
    } else {
      final afterIndex = _children.indexOf(after);

      if (afterIndex > -1) {
        _children.insert(afterIndex, value);
      } else {
        _children.add(value);
      }
    }

    value.parent = this;
    _propagateDepthToDescendants(value, depth);
  }

  BaseNode get rootNode {
    if (parent == null) {
      return this;
    } else {
      return parent!.rootNode;
    }
  }

  bool get isLeaf => _children.isEmpty;

  List<BaseNode> get children => List.unmodifiable(_children);

  @override
  bool operator ==(covariant BaseNode other) =>
      identical(this, other) || other.hashCode == hashCode;

  @override
  int get hashCode => id.hashCode ^ depth.hashCode;
}

class Node extends BaseNode with NodeLayout {
  Node({required String id}) : super(id: id);

  @override
  Node get rootNode {
    if (parent == null) {
      return this;
    } else {
      return parent!.rootNode as Node;
    }
  }

  @override
  String toString() {
    return "Node(width: $width, height: $height, position: $_position, parentId: ${parent?.id})";
  }
}

mixin NodeLayout on BaseNode {
  bool _debugHasLaidout = false;

  bool _debugHasNormalized = false;

  @override
  set size(Size value) {
    _size = value;
    _debugHasLaidout = true;
  }

  Size _normalizedSize = Size.zero;
  Size get normalizedSize => _normalizedSize;

  double getNormalizedMainAxis(TreeDirection direction) {
    assert(_debugHasNormalized);
    switch (direction) {
      case TreeDirection.top:
      case TreeDirection.bottom:
        return _normalizedSize.height;
      case TreeDirection.left:
      case TreeDirection.right:
        return _normalizedSize.width;
    }
  }

  double getNormalizedCrossAxis(TreeDirection direction) {
    assert(_debugHasNormalized);
    switch (direction) {
      case TreeDirection.top:
      case TreeDirection.bottom:
        return _normalizedSize.width;
      case TreeDirection.left:
      case TreeDirection.right:
        return _normalizedSize.height;
    }
  }

  void normalize({
    required TreeDirection direction,
    required double subtreeMainAxisSpacing,
    required double subtreeCrossSpacing,
  }) {
    assert(_debugHasLaidout, "Node not laid out");

    if (isLeaf) {
      _normalizedSize = _size;
    } else {
      double mainAxisSpace =
          subtreeMainAxisSpacing + getNormalizedMainAxis(direction);
      double crossAxisSpace = 0.0;

      double maxMainAxisNodeSpace = 0.0;

      for (final node in children) {
        assert(node is Node);

        (node as Node).normalize(
          direction: direction,
          subtreeMainAxisSpacing: subtreeMainAxisSpacing,
          subtreeCrossSpacing: subtreeCrossSpacing,
        );
        crossAxisSpace += node.getNormalizedCrossAxis(direction);
        maxMainAxisNodeSpace =
            max(maxMainAxisNodeSpace, node.getNormalizedMainAxis(direction));
      }

      crossAxisSpace += (children.length - 1) * subtreeCrossSpacing;
      mainAxisSpace += maxMainAxisNodeSpace;

      _normalizedSize = Size(mainAxisSpace, crossAxisSpace);
    }
    _debugHasNormalized = true;
  }

  /// [origin] the top-left of the normalized subtree
  void positionNode(TreeViewDelegate delegate, Offset origin) {
    assert(_debugHasNormalized);

    if (isLeaf) {
      _position = origin + Alignment.center.alongSize(_normalizedSize);
    } else {
      _position = origin + align(delegate.alignment, delegate.direction);
      _propagateOriginToDescendants(origin, delegate);
    }
  }

  void _propagateOriginToDescendants(Offset origin, TreeViewDelegate delegate) {
    double dx = 0.0;
    double dy = 0.0;

    switch (delegate.direction) {
      case TreeDirection.top:
        dy = height / 2 + delegate.mainAxisSpacing;
        break;
      case TreeDirection.bottom:
        dy = -(height / 2 + delegate.mainAxisSpacing);
        break;
      case TreeDirection.left:
        dx = width / 2 + delegate.mainAxisSpacing;
        break;
      case TreeDirection.right:
        dx = -(width / 2 + delegate.mainAxisSpacing);
        break;
    }

    for (final node in children) {
      (node as Node).positionNode(delegate, origin + Offset(dx, dy));
      switch (delegate.direction) {
        case TreeDirection.top:
        case TreeDirection.bottom:
          dx += node.getNormalizedCrossAxis(delegate.direction);
          break;
        case TreeDirection.left:
        case TreeDirection.right:
          dy += node.getNormalizedCrossAxis(delegate.direction);
          break;
      }
    }
  }

  Offset align(NodeAlignment alignment, TreeDirection direction) {
    Alignment directionAlignment = Alignment.topLeft;

    double dx = 0.0;
    double dy = 0.0;

    if (direction == TreeDirection.top) {
      dy = height / 2;

      switch (alignment) {
        case NodeAlignment.start:
          directionAlignment = Alignment.topLeft;
          dx = width / 2;
          break;
        case NodeAlignment.mid:
          directionAlignment = Alignment.topCenter;
          dx = 0;
          break;
        case NodeAlignment.end:
          directionAlignment = Alignment.topRight;
          dx = -width / 2;
          break;
      }
    }

    if (direction == TreeDirection.bottom) {
      dy = -height / 2;
      switch (alignment) {
        case NodeAlignment.start:
          directionAlignment = Alignment.bottomLeft;
          dx = width / 2;
          break;
        case NodeAlignment.mid:
          directionAlignment = Alignment.bottomCenter;
          dx = 0;
          break;
        case NodeAlignment.end:
          directionAlignment = Alignment.bottomRight;
          dx = -width / 2;
          break;
      }
    }

    if (direction == TreeDirection.left) {
      dx = width / 2;
      switch (alignment) {
        case NodeAlignment.start:
          directionAlignment = Alignment.topLeft;
          dy = height / 2;
          break;
        case NodeAlignment.mid:
          directionAlignment = Alignment.centerLeft;
          dy = 0;
          break;
        case NodeAlignment.end:
          directionAlignment = Alignment.bottomLeft;
          dy = -height / 2;
          break;
      }
    }

    if (direction == TreeDirection.right) {
      dx = -width / 2;
      switch (alignment) {
        case NodeAlignment.start:
          directionAlignment = Alignment.topRight;
          dy = height / 2;
          break;
        case NodeAlignment.mid:
          directionAlignment = Alignment.centerRight;
          dy = 0;
          break;
        case NodeAlignment.end:
          directionAlignment = Alignment.bottomRight;
          dy = -height / 2;
          break;
      }
    }

    return directionAlignment.alongSize(_normalizedSize) + Offset(dx, dy);
  }
}
