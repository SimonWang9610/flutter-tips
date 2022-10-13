import 'package:flutter/material.dart';
import 'package:flutter_tips/tree/tree_delegate.dart';

class MinimalTreeExample extends StatefulWidget {
  const MinimalTreeExample({Key? key}) : super(key: key);

  @override
  State<MinimalTreeExample> createState() => _MinimalTreeExampleState();
}

class _MinimalTreeExampleState extends State<MinimalTreeExample> {
  late final TreeNode root;

  @override
  void initState() {
    super.initState();

    root = TreeNode(
      style: const TextStyle(
        color: Colors.red,
        fontSize: 60,
      ),
      borderShape: BoxShape.rectangle,
      icon: Icons.add,
      // text: "add",
    );

    root.addNode(
      TreeNode(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 60,
        ),
        // text: "Red Light",
        icon: Icons.arrow_upward,
      ),
    );
    root.addNode(
      TreeNode(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 60,
        ),
        // maxWidth: 100,
        // text: "Red",
        borderShape: BoxShape.rectangle,
        icon: Icons.toggle_off,
        backgroundColor: Colors.yellow,
      ),
    );

    root.addNode(
      TreeNode(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 80,
        ),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),

        text: "Red",
        // icon: Icons.arrow_downward,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TreeViewPainter(
        root: root,
        borderRadius: BorderRadius.circular(20),
      ),
      size: const Size(100, 100),
    );
  }
}
