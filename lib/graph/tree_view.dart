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
  final TreeViewLayoutDelegate layoutDelegate;
  final TreeViewEdgePainter edgePainter;

  TreeView({
    Key? key,
    required this.root,
    required NodeWidgetBuilder<T> nodeBuilder,
    required this.layoutDelegate,
    required this.edgePainter,
    this.clipBehavior = Clip.hardEdge,
  }) : super(
          key: key,
          children: BaseNode.extractChildrenWidget(root, nodeBuilder),
        );

  @override
  RenderTreeView createRenderObject(BuildContext context) {
    return RenderTreeView<T>(
      root: root,
      layoutDelegate: layoutDelegate,
      edgePainter: edgePainter,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTreeView renderObject) {
    renderObject
      ..root = root
      ..layoutDelegate = layoutDelegate
      ..edgePainter = edgePainter
      ..clipBehavior = clipBehavior;
  }
}

class RenderTreeView<T extends BaseNode> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData>,
        DebugOverflowIndicatorMixin {
  T _root;
  TreeViewLayoutDelegate _layoutDelegate;
  TreeViewEdgePainter _edgePainter;
  Clip _clipBehavior;

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  /// [addAll] will iterate each widget to [insert] it to the children list
  /// [insert] will invoke [adoptChild] and then actually insert it to the children list
  /// [adoptChild] will first invoke [setupParentData] to initialize [NodeBoxData]
  RenderTreeView({
    required T root,
    required TreeViewLayoutDelegate layoutDelegate,
    required TreeViewEdgePainter edgePainter,
    Clip clipBehavior = Clip.hardEdge,
    List<RenderBox>? children,
  })  : _root = root,
        _layoutDelegate = layoutDelegate,
        _clipBehavior = clipBehavior,
        _edgePainter = edgePainter {
    addAll(children);
  }

  T get root => _root;

  /// TODO: optimize checking if two trees are identical
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
      // oldDelegate.removeListener(markNeedsLayout);
      oldDelegate.dispose();
      _layoutDelegate.addListener(markNeedsLayout);
    }
  }

  TreeViewEdgePainter get edgePainter => _edgePainter;
  set edgePainter(TreeViewEdgePainter value) {
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
      // oldPainter.removeListener(markNeedsPaint);
      oldPainter.dispose();
      _edgePainter.addListener(markNeedsPaint);
    }
  }

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
    final actualSize = _layoutDelegate.layout(constraints.loosen(), firstChild);

    size = constraints.constrain(actualSize);

    if (size.width < actualSize.width || size.height < actualSize.height) {
      _hasOverflow = true;
    }
  }

  bool _hasOverflow = false;

  /// TODO: paint edges between nodes
  /// TODO: paint the overflow rect more exactly
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
    _clipRectLayer.layer = null;
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

typedef TreeViewLayoutBuilder = Size Function(
    BoxConstraints, TreeDirection direction, RenderBox?);

class TreeViewLayoutDelegate extends ChangeNotifier {
  final TreeViewLayoutBuilder? layoutBuilder;

  double _mainAxisSpacing;
  double _crossAxisSpacing;
  TreeDirection _direction;
  NodeAlignment _alignment;

  TreeViewLayoutDelegate({
    this.layoutBuilder,
    double crossAxisSpacing = 20.0,
    double mainAxisSpacing = 25.0,
    TreeDirection direction = TreeDirection.top,
    NodeAlignment alignment = NodeAlignment.mid,
    Paint? edgePaint,
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

  @protected
  bool shouldRelayout(covariant TreeViewLayoutDelegate oldDelegate) => true;

  Size layout(BoxConstraints constraints, RenderBox? child) {
    if (layoutBuilder != null) {
      return layoutBuilder!(constraints, direction, child);
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

typedef TreeViewEdgeBuilder<T extends BaseNode> = void Function(
    T, Canvas, Offset);

class TreeViewEdgePainter extends ChangeNotifier {
  static final Paint _defaultEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.black
    ..strokeCap = StrokeCap.butt;

  static void _defaultEdgePainter(BaseNode root, Canvas canvas, Offset offset,
      {Paint? edgePaint}) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    final edges = BaseNode.extractEdges(root);

    for (final edge in edges) {
      canvas.drawPath(edge, edgePaint ?? _defaultEdgePaint);
    }

    canvas.restore();
  }

  final TreeViewEdgeBuilder? edgePainter;
  Paint? _paint;

  TreeViewEdgePainter({
    Paint? paint,
    this.edgePainter,
  }) : _paint = paint;

  Paint? get paint => _paint;
  set paint(Paint? value) {
    if (_paint != value) {
      _paint = value;
      notifyListeners();
    }
  }

  @protected
  bool shouldRepaint(covariant TreeViewEdgePainter oldPainter) => true;

  void paintEdges<T extends BaseNode>(T root, Canvas canvas, Offset offset) {
    if (edgePainter != null) {
      edgePainter!(root, canvas, offset);
    } else {
      _defaultEdgePainter(
        root,
        canvas,
        offset,
        edgePaint: paint ?? _defaultEdgePaint,
      );
    }
  }
}
