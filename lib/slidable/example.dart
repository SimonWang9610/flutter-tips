import 'package:flutter/material.dart';
import 'package:flutter_tips/slidable/action_motion.dart';
import 'package:flutter_tips/slidable/models.dart';
import 'package:flutter_tips/slidable/render.dart';
import 'package:flutter_tips/slidable/slide_action_panel.dart';
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
    return SlidablePanel(
      axis: Axis.horizontal,
      preActionPanelBuilder: (_, percent) {
        return SlideActionPanel(
          slidePercent: percent,
          actionLayout: ActionLayout.spaceEvenly(),
          actions: [
            ActionItem(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.green),
                child: Center(
                  child: Text("Delete"),
                ),
              ),
            ),
            ActionItem(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.red,
                ),
                child: Center(
                  child: Text("Add"),
                ),
              ),
            ),
          ],
        );
      },
      postActionPanelBuilder: (_, percent) {
        return SlideActionPanel(
          slidePercent: percent,
          actionLayout: ActionLayout.spaceEvenly(),
          actions: const [
            ActionItem(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.red),
                child: Center(
                  child: Text("Delete"),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(color: Colors.green),
              child: Center(
                child: Text("Add"),
              ),
            ),
          ],
        );
      },
      child: InkWell(
        onTap: () => print("Slidable"),
        child: const DecoratedBox(
          decoration: BoxDecoration(color: Colors.blue),
          child: SizedBox(
            width: 300,
            height: 160,
            child: Center(
              child: Text("Slidable"),
            ),
          ),
        ),
      ),
    );
  }
}
