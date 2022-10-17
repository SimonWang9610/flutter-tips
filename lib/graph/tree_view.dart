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

class TreeView<T extends BaseNode> extends MultiChildRenderObjectWidget {
  final T root;
  final Clip clipBehavior;
  final TreeViewDelegate delegate;

  TreeView({
    Key? key,
    required this.root,
    required NodeWidgetBuilder<T> nodeBuilder,
    required this.delegate,
    this.clipBehavior = Clip.hardEdge,
  }) : super(
          key: key,
          children: BaseNode.extractChildrenWidget(root, nodeBuilder),
        );

  @override
  RenderTreeView createRenderObject(BuildContext context) {
    return RenderTreeView<T>(
      root: root,
      delegate: delegate,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTreeView renderObject) {
    renderObject
      ..root = root
      ..delegate = delegate
      ..clipBehavior = clipBehavior;
  }
}

class RenderTreeView<T extends BaseNode> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData>,
        DebugOverflowIndicatorMixin {
  static final Paint _defaultEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.black
    ..strokeCap = StrokeCap.butt;

  T _root;
  TreeViewDelegate _delegate;
  Clip _clipBehavior;

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  /// [addAll] will iterate each widget to [insert] it to the children list
  /// [insert] will invoke [adoptChild] and then actually insert it to the children list
  /// [adoptChild] will first invoke [setupParentData] to initialize [NodeBoxData]
  RenderTreeView({
    required T root,
    required TreeViewDelegate delegate,
    Clip clipBehavior = Clip.hardEdge,
    List<RenderBox>? children,
  })  : _root = root,
        _delegate = delegate,
        _clipBehavior = clipBehavior {
    addAll(children);
  }

  void _handleDelegateChanges() {
    markNeedsLayout();
  }

  T get root => _root;

  /// TODO: optimize checking if two trees are identical
  set root(T value) {
    if (!_root.isSameTree(value)) {
      _root = value;
      markNeedsLayout();
    }
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

  bool _hasOverflow = false;

  Clip get clipBehavior => _clipBehavior;
  set clipBehavior(Clip value) {
    if (_clipBehavior != value) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  /// call [BoxConstraints.constrain] to ensure [size] can pass [debugAssertDoesMeetConstraints]
  @override
  void performLayout() {
    final actualSize = _delegate.layout(constraints.loosen(), firstChild);

    size = constraints.constrain(actualSize);

    if (size.width < actualSize.width || size.height < actualSize.height) {
      _hasOverflow = true;
    }
  }

  /// TODO: paint edges between nodes
  /// TODO: paint the overflow rect more exactly
  @override
  void paint(PaintingContext context, Offset offset) {
    // context.canvas.save();
    // context.canvas.translate(offset.dx, offset.dy);

    if (!_hasOverflow) {
      defaultPaint(context, offset);
      return;
    }

    if (size.isEmpty) {
      return;
    }

    _clipRectLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
      clipBehavior: clipBehavior,
      oldLayer: _clipRectLayer.layer,
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
          'than the available space, consider clipping it with a ClipRect widget '
          'before putting it in the flex, or using a scrollable container rather '
          'than a Flex, like a ListView.',
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
  void dispose() {
    _clipRectLayer.layer = null;
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
    properties.add(DiagnosticsProperty<TreeViewDelegate>('delegate', delegate));
  }
}

typedef TreeViewLayoutBuilder = Size Function(
    BoxConstraints, TreeDirection direction, RenderBox?);
typedef TreeViewEdgeBuilder<T extends BaseNode> = void Function(T);

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
    double mainAxisSpacing = 25.0,
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

    // if (constraints.maxWidth > rootNode.normalizedSize.width ||
    //     constraints.maxHeight > rootNode.normalizedSize.height) {}

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
