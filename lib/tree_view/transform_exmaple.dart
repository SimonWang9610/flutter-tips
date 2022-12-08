import 'dart:math';

import 'package:flutter/material.dart';

import 'node.dart';
import 'tree_view.dart';
import 'tree_edge_painter.dart';
import 'tree_layout_delegate.dart';

class TransformTreeViewExample extends StatefulWidget {
  const TransformTreeViewExample({Key? key}) : super(key: key);

  @override
  State<TransformTreeViewExample> createState() =>
      _TransformTreeViewExampleState();
}

class _TransformTreeViewExampleState extends State<TransformTreeViewExample> {
  late final Node root = Node(
    id: "root",
    builder: (context) {
      return const SizedBox.square(
        dimension: 100,
        child: Center(
          child: Text(
            "Root",
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );

  final delegate = TreeViewLayoutDelegate(
    direction: TreeDirection.top,
    alignment: NodeAlignment.start,
    mainAxisSpacing: 20,
    crossAxisSpacing: 10,
  );

  final edgePainter = TransformEdgePainter();

  Node? _selectedNode;

  double _scale = 1.0;
  bool _autoScale = true;

  void _addNode() {
    if (_selectedNode == null) return;

    final length = _selectedNode!.children.length;
    final id = "${_selectedNode!.id}: ${length + 1}";

    _selectedNode!.addChild(
      Node(
        id: id,
        builder: (context) => SizedBox.square(
          dimension: 40,
          child: Text(
            id,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    setState(() {});
  }

  void _removeNode() {
    if (_selectedNode == null || _selectedNode?.parent == null) return;

    _selectedNode!.parent!.removeChild(_selectedNode!.id);
    setState(() {});
  }

  @override
  void dispose() {
    edgePainter.dispose();
    delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transform Tree View example"),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedNode?.id ?? "No node selected",
                textAlign: TextAlign.center,
              ),
              IconButton(
                onPressed: _addNode,
                icon: const Icon(
                  Icons.add,
                  color: Colors.green,
                ),
              ),
              IconButton(
                onPressed: _removeNode,
                icon: const Icon(
                  Icons.remove,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  delegate.direction = TreeDirection.top;
                },
                child: const Text("Top"),
              ),
              TextButton(
                onPressed: () {
                  delegate.direction = TreeDirection.bottom;
                },
                child: const Text("bottom"),
              ),
              TextButton(
                onPressed: () {
                  delegate.direction = TreeDirection.left;
                },
                child: const Text("left"),
              ),
              TextButton(
                onPressed: () {
                  delegate.direction = TreeDirection.right;
                },
                child: const Text("right"),
              ),
              TextButton(
                onPressed: () {
                  final random = Random();
                  final paint = Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Colors
                        .primaries[random.nextInt(Colors.primaries.length)]
                    ..strokeCap = StrokeCap.butt;

                  edgePainter.paint = paint;
                },
                child: const Text("random edge paint"),
              ),
            ],
          ),
          Row(
            children: [
              const Text("scale: "),
              IconButton(
                onPressed: () {
                  _scale += 0.1;
                  edgePainter.transform = Matrix4.identity()..scale(_scale);
                },
                icon: const Icon(
                  Icons.add,
                  color: Colors.green,
                ),
              ),
              IconButton(
                onPressed: () {
                  _scale -= 0.1;
                  edgePainter.transform = Matrix4.identity()..scale(_scale);
                },
                icon: const Icon(
                  Icons.remove,
                  color: Colors.red,
                ),
              ),
              TextButton(
                onPressed: () {
                  _autoScale = !_autoScale;
                  setState(() {});
                },
                child: const Text("switch auto scale"),
              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all()),
              child: TreeView.transform<Node>(
                root: root,
                autoScale: _autoScale,
                nodeBuilder: (node) {
                  return DecoratedBox(
                    decoration: BoxDecoration(border: Border.all()),
                    child: GestureDetector(
                      onTap: () {
                        _selectedNode = node;
                        setState(() {});
                      },
                      child: node.builder(context),
                    ),
                  );
                },
                layoutDelegate: delegate,
                edgePainter: edgePainter,
              ),
            ),
          )
        ],
      ),
    );
  }

  Matrix4 getTransform() {
    return Matrix4.identity()..scale(_scale);
  }
}
