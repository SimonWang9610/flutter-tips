import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'node.dart';
import 'tree_edge_painter.dart';
import 'tree_layout_delegate.dart';
import 'tree_view.dart';

class ScrollableTreeViewExample extends StatefulWidget {
  const ScrollableTreeViewExample({Key? key}) : super(key: key);

  @override
  State<ScrollableTreeViewExample> createState() =>
      _ScrollableTreeViewExampleState();
}

class _ScrollableTreeViewExampleState extends State<ScrollableTreeViewExample> {
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

  final edgePainter = ClipEdgePainter();

  Node? _selectedNode;
  Offset _delta = Offset.zero;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clip Tree View example"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_selectedNode?.id ?? "No node selected"),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                  onPressed: () {
                    delegate.alignment = NodeAlignment.start;
                  },
                  child: const Text("start")),
              TextButton(
                  onPressed: () {
                    delegate.alignment = NodeAlignment.mid;
                  },
                  child: const Text("mid")),
              TextButton(
                  onPressed: () {
                    delegate.alignment = NodeAlignment.end;
                  },
                  child: const Text("end")),
              TextButton(
                onPressed: () {
                  _delta = Offset.zero;
                  setState(() {});
                },
                child: Text("restore"),
              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                final shift = details.delta;
                _delta = shift;
                print("current delta: $_delta, once delta: $shift");
                setState(() {});
              },
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border.all()),
                child: TreeView.clip<Node>(
                  root: root,
                  delta: _delta,
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
            ),
          )
        ],
      ),
    );
  }
}
