import 'package:flutter/material.dart';

import 'node.dart';
import 'tree_view.dart';

class TreeViewExample extends StatefulWidget {
  const TreeViewExample({Key? key}) : super(key: key);

  @override
  State<TreeViewExample> createState() => _TreeViewExampleState();
}

class _TreeViewExampleState extends State<TreeViewExample> {
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

  Node? _selectedNode;

  @override
  void initState() {
    super.initState();

    // final firstNode = Node(
    //   id: "first",
    //   builder: (context) {
    //     return const SizedBox.square(
    //       dimension: 50,
    //       child: Center(
    //         child: Text(
    //           "First",
    //           textAlign: TextAlign.center,
    //         ),
    //       ),
    //     );
    //   },
    // );

    // firstNode.addChild(Node(
    //   id: "first-first",
    //   builder: (context) {
    //     return const SizedBox.square(
    //       dimension: 50,
    //       child: Center(
    //         child: Text(
    //           "11",
    //           textAlign: TextAlign.center,
    //         ),
    //       ),
    //     );
    //   },
    // ));
    // firstNode.addChild(Node(
    //   id: "12",
    //   builder: (context) {
    //     return const SizedBox.square(
    //       dimension: 50,
    //       child: Center(
    //         child: Text(
    //           "12",
    //           textAlign: TextAlign.center,
    //         ),
    //       ),
    //     );
    //   },
    // ));

    // final thirdNode = Node(
    //   id: "Third",
    //   builder: (context) {
    //     return const SizedBox.square(
    //       dimension: 60,
    //       child: Center(
    //         child: Text(
    //           "Third",
    //           textAlign: TextAlign.center,
    //         ),
    //       ),
    //     );
    //   },
    // );

    // thirdNode.addChild(Node(
    //   id: "31",
    //   builder: (context) {
    //     return const SizedBox.square(
    //       dimension: 60,
    //       child: Center(
    //         child: Text(
    //           "31",
    //           textAlign: TextAlign.center,
    //         ),
    //       ),
    //     );
    //   },
    // ));
    // thirdNode.addChild(Node(
    //   id: "32",
    //   builder: (context) {
    //     return const SizedBox.square(
    //       dimension: 50,
    //       child: Center(
    //         child: Text(
    //           "32",
    //           textAlign: TextAlign.center,
    //         ),
    //       ),
    //     );
    //   },
    // ));

    // root.addChild(firstNode);
    // root.addChild(Node(
    //   id: "second",
    //   builder: (context) {
    //     return SizedBox(
    //       width: 100,
    //       height: 200,
    //       child: ListView.builder(
    //         itemCount: 20,
    //         itemBuilder: (context, index) => Text("Second: $index"),
    //       ),
    //     );
    //   },
    // ));
    // root.addChild(thirdNode);
  }

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
    return Column(
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
        const SizedBox(
          height: 20,
        ),
        Expanded(
          child: TreeView<Node>(
            root: root,
            nodeBuilder: (node) {
              return DecoratedBox(
                decoration: BoxDecoration(border: Border.all()),
                child: GestureDetector(
                  onTap: () {
                    print("tap on: ${node.id}");
                    _selectedNode = node;
                    setState(() {});
                  },
                  child: node.builder(context),
                ),
              );
            },
            delegate: TreeViewDelegate(
              direction: TreeDirection.top,
              alignment: NodeAlignment.mid,
              mainAxisSpacing: 20,
              crossAxisSpacing: 10,
            ),
          ),
        )
      ],
    );
  }
}
