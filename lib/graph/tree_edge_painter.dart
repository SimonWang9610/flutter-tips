import 'package:flutter/material.dart';

import 'node.dart';

typedef TreeViewEdgeBuilder<T extends BaseNode> = void Function(
    T, Canvas, Offset);

abstract class TreeViewEdgePainter extends ChangeNotifier {
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

class ClipEdgePainter extends TreeViewEdgePainter {
  ClipEdgePainter({
    super.paint,
    super.edgePainter,
    Clip clipBehavior = Clip.hardEdge,
  }) : _clipBehavior = clipBehavior;

  Clip _clipBehavior;

  Clip get clipBehavior => _clipBehavior;
  set clipBehavior(Clip value) {
    if (_clipBehavior != value) {
      _clipBehavior = value;
      notifyListeners();
    }
  }
}

class TransformEdgePainter extends TreeViewEdgePainter {
  TransformEdgePainter({
    super.paint,
    super.edgePainter,
    Matrix4? transform,
  }) : _transform = transform;

  Matrix4? _transform;

  Matrix4? get transform => _transform;
  set transform(Matrix4? value) {
    if (_transform != value) {
      _transform = value;
      notifyListeners();
    }
  }
}
