import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/graph/node_widget.dart';
import 'package:flutter_tips/graph/tree_view.dart';

typedef NodeWidgetBuilder<T extends BaseNode> = Widget Function(T);

abstract class BaseNode {
  static void _propagateDepthToDescendants(BaseNode child, int parentDepth) {
    child.depth = parentDepth + 1;

    for (final node in child._children) {
      _propagateDepthToDescendants(node, child.depth);
    }
  }

  static List<Widget> extractChildrenWidget<T extends BaseNode>(
      T root, NodeWidgetBuilder<T> builder) {
    final List<Widget> widgets = [];

    widgets.add(
      NodeWidget(
        node: root,
        child: builder(root),
      ),
    );

    /// depth first recursion
    for (final node in root.children.cast<T>()) {
      widgets.addAll(extractChildrenWidget(node, builder));
    }

    return widgets;
  }

  /// unique identity for a node
  final String id;

  /// child nodes
  final List<BaseNode> _children = [];

  /// parent node of this node
  BaseNode? parent;
  int depth = 0;

  bool _debugHasLaidout = false;

  Size _size = Size.zero;
  double get height => _size.height;
  double get width => _size.width;
  Size get size => _size;

  set size(Size value) {
    _size = value;
    _debugHasLaidout = true;
  }

  bool _debugHasNormalized = false;

  Size _normalizedSize = Size.zero;
  Size get normalizedSize => _normalizedSize;

  /// the center position of the node widget
  Offset _position = Offset.zero;
  Offset get offset => _position - Alignment.center.alongSize(_size);

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

  void removeChild(String id) {
    _children.removeWhere((element) => element.id == id);
  }

  /// get the top-most root node
  BaseNode get rootNode {
    if (parent == null) {
      return this;
    } else {
      return parent!.rootNode;
    }
  }

  bool get isLeaf => _children.isEmpty;

  List<BaseNode> get children => List.unmodifiable(_children);

  void normalize({
    required TreeDirection direction,
    required double subtreeMainAxisSpacing,
    required double subtreeCrossSpacing,
    double scaleX = 1.0,
    double scaleY = 1.0,
  });

  void positionNode(TreeViewDelegate delegate, Offset origin);

  double getNormalizedMainAxis(TreeDirection direction);
  double getNormalizedCrossAxis(TreeDirection direction);
  double getMainAxis(TreeDirection direction);

  void setNormalizedSize(
      double mainAxis, double crossAxis, TreeDirection direction);
  Offset calculateNormalizedBaseline(
      TreeDirection direction, double mainAxisSpacing, double crossAxisSpacing);

  bool isSameTree(BaseNode other) {
    bool isSame = true;

    if (this != other) {
      isSame = false;
    } else if (children.length != other.children.length) {
      isSame = false;
    } else {
      for (int i = 0; i < children.length; i++) {
        isSame = isSame && children[i].isSameTree(other.children[i]);
      }
    }
    return isSame;
  }

  @override
  bool operator ==(covariant BaseNode other) =>
      identical(this, other) || other.hashCode == hashCode;

  @override
  int get hashCode => id.hashCode ^ depth.hashCode;
}

class Node extends BaseNode with NodeLayout {
  final WidgetBuilder builder;
  Node({
    required String id,
    required this.builder,
  }) : super(id: id);

  @override
  String toString() {
    return "Node(width: $width, height: $height, position: $_position, parentId: ${parent?.id})";
  }
}

mixin NodeLayout on BaseNode {
  @override
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

  @override
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

  @override
  double getMainAxis(TreeDirection direction) {
    assert(_debugHasLaidout);

    switch (direction) {
      case TreeDirection.top:
      case TreeDirection.bottom:
        return height;
      case TreeDirection.left:
      case TreeDirection.right:
        return width;
    }
  }

  double getMainAxisScale(
      double scaleX, double scaleY, TreeDirection direction) {
    switch (direction) {
      case TreeDirection.top:
      case TreeDirection.bottom:
        return scaleY;
      case TreeDirection.left:
      case TreeDirection.right:
        return scaleX;
    }
  }

  double getCrossAxisScale(
      double scaleX, double scaleY, TreeDirection direction) {
    switch (direction) {
      case TreeDirection.top:
      case TreeDirection.bottom:
        return scaleX;
      case TreeDirection.left:
      case TreeDirection.right:
        return scaleY;
    }
  }

  /// normalize the node size by depth first recursion
  /// 1) if the node is a leaf node, there is nothing to do
  /// 2) if the node has children, we must first normalize its all children
  ///   so that we could regard all its subtree (rooted in its children) as a special leaf node
  ///   therefore simplifying position processing
  ///
  /// when [setNormalizedSize], [direction] will determine how to set the normalized size using [mainAxis] and [crossAxis]:
  /// for [TreeDirection.top] and [TreeDirection.bottom], [subtreeMainAxisSpacing works on the vertical (dy)
  ///  [subtreeCrossSpacing] works on horizontal (dx)
  /// for [TreeDirection.left] and [TreeDirection.right], [subtreeMainAxisSpacing works on the vertical (dx)
  ///  [subtreeCrossSpacing] works on horizontal (dy)
  @override
  void normalize({
    required TreeDirection direction,
    required double subtreeMainAxisSpacing,
    required double subtreeCrossSpacing,
    double scaleX = 1.0,
    double scaleY = 1.0,
  }) {
    assert(_debugHasLaidout, "Node not laid out");

    if (isLeaf) {
      _normalizedSize = _size;
    } else {
      // default TreeDirection.top
      double mainAxisSpace = subtreeMainAxisSpacing + getMainAxis(direction);
      double crossAxisSpace = 0.0;

      double maxMainAxisNodeSpace = 0.0;

      for (final node in children) {
        node.normalize(
          direction: direction,
          subtreeMainAxisSpacing: subtreeMainAxisSpacing,
          subtreeCrossSpacing: subtreeCrossSpacing,
          scaleX: scaleX,
          scaleY: scaleY,
        );
        crossAxisSpace += node.getNormalizedCrossAxis(direction);
        maxMainAxisNodeSpace =
            max(maxMainAxisNodeSpace, node.getNormalizedMainAxis(direction));
      }

      crossAxisSpace += (children.length - 1) * subtreeCrossSpacing;
      mainAxisSpace += maxMainAxisNodeSpace;

      // _normalizedSize = Size(mainAxisSpace, crossAxisSpace);
      setNormalizedSize(mainAxisSpace, crossAxisSpace, direction);
    }
    _debugHasNormalized = true;
  }

  /// for each normalized node, [origin] always is the top-left corner
  /// invoke [_align] to calculate its offset relative to this normalized node
  /// then [_propagateOriginToDescendants] to position all its normalized children
  @override
  void positionNode(TreeViewDelegate delegate, Offset origin) {
    assert(_debugHasNormalized);

    if (isLeaf) {
      _position = origin + Alignment.center.alongSize(_normalizedSize);
    } else {
      _position = origin + _align(delegate.alignment, delegate.direction);
      _propagateOriginToDescendants(origin, delegate);
    }
  }

  @override
  void setNormalizedSize(
      double mainAxis, double crossAxis, TreeDirection direction) {
    switch (direction) {
      case TreeDirection.top:
      case TreeDirection.bottom:
        _normalizedSize = Size(crossAxis, mainAxis);
        break;
      case TreeDirection.left:
      case TreeDirection.right:
        _normalizedSize = Size(mainAxis, crossAxis);
        break;
    }
  }

  /// the baseline is mainly used to mark the relative main-axis position between normalized children and this node
  @override
  Offset calculateNormalizedBaseline(TreeDirection direction,
      double mainAxisSpacing, double crossAxisSpacing) {
    double dx = 0.0;
    double dy = 0.0;

    switch (direction) {
      case TreeDirection.top:
        dx = 0.0;
        dy = height + mainAxisSpacing;
        break;
      case TreeDirection.left:
        dx = width + mainAxisSpacing;
        dy = 0.0;
        break;
      case TreeDirection.bottom:
        dx = 0.0;
        dy = _normalizedSize.height - mainAxisSpacing - height;
        break;
      case TreeDirection.right:
        dx = _normalizedSize.width - mainAxisSpacing - width;
        dy = 0.0;
        break;
    }
    return Offset(dx, dy);
  }

  /// once the baseline is determined, we only need to calculate the cross-axis shift by [TreeViewDelegate.direction]
  ///
  void _propagateOriginToDescendants(Offset origin, TreeViewDelegate delegate) {
    final baseline = calculateNormalizedBaseline(delegate.direction,
            delegate.mainAxisSpacing, delegate.crossAxisSpacing) +
        origin;

    double dx = 0.0;
    double dy = 0.0;

    for (final node in children) {
      Offset shift = Offset.zero;

      switch (delegate.direction) {
        case TreeDirection.top:
        case TreeDirection.left:
          shift = Offset(dx, dy);
          break;
        case TreeDirection.bottom:
          shift = Offset(dx, -node.getNormalizedMainAxis(delegate.direction));
          break;
        case TreeDirection.right:
          shift = Offset(-node.getNormalizedMainAxis(delegate.direction), dy);
          break;
      }

      node.positionNode(delegate, baseline + shift);

      switch (delegate.direction) {
        case TreeDirection.top:
        case TreeDirection.bottom:
          dx += node.getNormalizedCrossAxis(delegate.direction) +
              delegate.crossAxisSpacing;
          break;
        case TreeDirection.left:
        case TreeDirection.right:
          dy += node.getNormalizedCrossAxis(delegate.direction) +
              delegate.crossAxisSpacing;
          break;
      }
    }
  }

  Offset _align(NodeAlignment alignment, TreeDirection direction) {
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
