import 'package:flutter/material.dart';
import 'package:flutter_tips/slidable/render.dart';
import 'package:flutter_tips/slidable/widget.dart';

import 'package:flutter_slidable/flutter_slidable.dart';

class SlidableExample extends StatefulWidget {
  const SlidableExample({super.key});

  @override
  State<SlidableExample> createState() => _SlidableExampleState();
}

class _SlidableExampleState extends State<SlidableExample> {
  @override
  Widget build(BuildContext context) {
    return const SlidablePanel(
      preActions: [
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.red),
          child: Center(
            child: Text("Delete"),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.green),
          child: Center(
            child: Text("Delete"),
          ),
        ),
      ],
      postActions: [
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.green),
          child: Center(
            child: Text("Add"),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.red),
          child: Center(
            child: Text("Add"),
          ),
        ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.blue),
        child: SizedBox(
          width: 300,
          height: 100,
          child: Center(
            child: Text("Slidable"),
          ),
        ),
      ),
    );
  }
}
