import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'node.dart';

typedef TreeViewLayoutBuilder = Size Function(
    BoxConstraints, TreeDirection direction, RenderBox?);

enum TreeDirection {
  top,
  bottom,
  left,
  right,
}

enum NodeAlignment {
  start,
  mid,
  end,
}

class NodeBoxData<T extends BaseNode>
    extends ContainerBoxParentData<RenderBox> {
  T? node;
}

/// [TreeDirection] would be the direction of the root node and also indicate the main-axis
/// [mainAxisSpacing] : the spacing between the root bottom-center and the child's top-center on the main axis
/// (all children would share the same [mainAxisSpacing])
/// [crossAxisSpacing] : the spacing between two adjacent siblings on the cross axis
/// [NodeAlignment] : the position of the root of the normalized subtree relative to the subtree's normalized size
class TreeViewLayoutDelegate extends ChangeNotifier {
  double _mainAxisSpacing;
  double _crossAxisSpacing;
  TreeDirection _direction;
  NodeAlignment _alignment;
  TreeViewLayoutBuilder? _layoutBuilder;

  TreeViewLayoutDelegate({
    TreeViewLayoutBuilder? layoutBuilder,
    double crossAxisSpacing = 20.0,
    double mainAxisSpacing = 25.0,
    TreeDirection direction = TreeDirection.top,
    NodeAlignment alignment = NodeAlignment.mid,
  })  : _mainAxisSpacing = mainAxisSpacing,
        _crossAxisSpacing = crossAxisSpacing,
        _direction = direction,
        _alignment = alignment,
        _layoutBuilder = layoutBuilder;

  double get mainAxisSpacing => _mainAxisSpacing;
  set mainAxisSpacing(double value) {
    if (_mainAxisSpacing != value) {
      _mainAxisSpacing = value;
      notifyListeners();
    }
  }

  double get crossAxisSpacing => _crossAxisSpacing;
  set crossAxisSpacing(double value) {
    if (_crossAxisSpacing != value) {
      _crossAxisSpacing = value;
      notifyListeners();
    }
  }

  TreeDirection get direction => _direction;
  set direction(TreeDirection direction) {
    print("set direction: $direction");
    if (_direction != direction) {
      _direction = direction;
      notifyListeners();
    }
  }

  NodeAlignment get alignment => _alignment;
  set alignment(NodeAlignment value) {
    if (_alignment != value) {
      _alignment = value;
      notifyListeners();
    }
  }

  set layoutBuilder(TreeViewLayoutBuilder? value) {
    if (_layoutBuilder != value) {
      _layoutBuilder = value;
      notifyListeners();
    }
  }

  @protected
  bool shouldRelayout(covariant TreeViewLayoutDelegate oldDelegate) => true;

  Size layout(BoxConstraints constraints, RenderBox? child) {
    if (_layoutBuilder != null) {
      return _layoutBuilder!(constraints, direction, child);
    } else {
      return _defaultLayoutDelegate(constraints, this, child);
    }
  }

  static Size _defaultLayoutDelegate(BoxConstraints constraints,
      TreeViewLayoutDelegate delegate, RenderBox? child) {
    assert(child != null);

    final parentData = child!.parentData as NodeBoxData;

    assert(parentData.node != null, "Not applyParentData: NodeBoxData");

    final rootNode = parentData.node!.rootNode;

    RenderBox? firstChild = child;

    /// layout all node widgets and set their sizes
    while (child != null) {
      final nodeBoxData = child.parentData as NodeBoxData;
      assert(nodeBoxData.node != null, "Not applyParentData: NodeBoxData");

      ChildLayoutHelper.layoutChild(child, constraints);

      nodeBoxData.node!.size = child.size;
      child = nodeBoxData.nextSibling;
    }

    rootNode.normalize(
      direction: delegate.direction,
      subtreeMainAxisSpacing: delegate.mainAxisSpacing,
      subtreeCrossSpacing: delegate.crossAxisSpacing,
    );

    rootNode.positionNode(
      delegate,
      Offset.zero,
    );

    child = firstChild;

    while (child != null) {
      final nodeBoxData = child.parentData as NodeBoxData;

      nodeBoxData.offset = nodeBoxData.node!.offset;
      child = nodeBoxData.nextSibling;
    }

    return rootNode.normalizedSize;
  }
}
