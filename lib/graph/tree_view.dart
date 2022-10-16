import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'node.dart';

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

class TreeView extends MultiChildRenderObjectWidget {
  final Node root;
  final TreeViewDelegate delegate;

  TreeView({
    Key? key,
    required this.root,
    required NodeWidgetBuilder nodeBuilder,
    required this.delegate,
  }) : super(
          key: key,
          children: BaseNode.extractChildrenWidget(root, nodeBuilder),
        );

  @override
  RenderTreeView createRenderObject(BuildContext context) {
    return RenderTreeView(
      root: root,
      delegate: delegate,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTreeView renderObject) {
    renderObject
      ..root = root
      ..delegate = delegate;
  }
}

class RenderTreeView extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData> {
  static final Paint _defaultEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.black
    ..strokeCap = StrokeCap.butt;

  Node _root;
  TreeViewDelegate _delegate;

  /// [addAll] will iterate each widget to [insert] it to the children list
  /// [insert] will invoke [adoptChild] and then actually insert it to the children list
  /// [adoptChild] will first invoke [setupParentData] to initialize [NodeBoxData]
  RenderTreeView({
    required Node root,
    required TreeViewDelegate delegate,
    List<RenderBox>? children,
  })  : _root = root,
        _delegate = delegate {
    addAll(children);
  }

  void _handleDelegateChanges() {
    markNeedsLayout();
  }

  Node get root => _root;
  set root(Node value) {
    _root = value;
    markNeedsLayout();
  }

  TreeViewDelegate get delegate => _delegate;
  set delegate(TreeViewDelegate value) {
    if (_delegate == value) {
      return;
    }

    final TreeViewDelegate oldDelegate = _delegate;
    if (oldDelegate.runtimeType != value.runtimeType) {
      markNeedsLayout();
    }
    _delegate = value;

    if (attached) {
      oldDelegate.removeListener(_handleDelegateChanges);
      _delegate.addListener(_handleDelegateChanges);
    }
  }

  @override
  void performLayout() {
    if (root.isLeaf) {
      size = constraints.biggest;
      return;
    }

    size = _delegate.layout(constraints.loosen(), firstChild);
  }

  @override
  void paint(PaintingContext context, Offset offset) {}

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeBoxData) {
      child.parentData = NodeBoxData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _delegate.addListener(_handleDelegateChanges);
  }

  @override
  void detach() {
    _delegate.removeListener(_handleDelegateChanges);
    super.detach();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Node>('root', root));
    properties.add(DiagnosticsProperty<TreeViewDelegate>('delegate', delegate));
  }
}

typedef TreeViewLayoutBuilder = Size Function(
    BoxConstraints, TreeDirection direction, RenderBox?);
typedef TreeViewEdgeBuilder = void Function(Node);

class TreeViewDelegate extends ChangeNotifier {
  final TreeViewLayoutBuilder? layoutDelegate;
  final TreeViewEdgeBuilder? edgePainter;

  double _mainAxisSpacing;
  double _crossAxisSpacing;
  TreeDirection _direction;
  NodeAlignment _alignment;

  TreeViewDelegate({
    this.edgePainter,
    this.layoutDelegate,
    double crossAxisSpacing = 20.0,
    double mainAxisSpacing = 50.0,
    TreeDirection direction = TreeDirection.top,
    NodeAlignment alignment = NodeAlignment.mid,
  })  : _mainAxisSpacing = mainAxisSpacing,
        _crossAxisSpacing = crossAxisSpacing,
        _direction = direction,
        _alignment = alignment;

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

  Size layout(BoxConstraints constraints, RenderBox? child) {
    if (layoutDelegate != null) {
      return layoutDelegate!(constraints, direction, child);
    } else {
      return _defaultLayoutDelegate(constraints, this, child);
    }
  }

  static Size _defaultLayoutDelegate(
      BoxConstraints constraints, TreeViewDelegate delegate, RenderBox? child) {
    assert(child != null);

    final parentData = child!.parentData as NodeBoxData;

    assert(parentData.node != null, "Not applyParentData: NodeBoxData");

    final rootNode = parentData.node!.rootNode as Node;

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
