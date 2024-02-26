import 'package:flutter/material.dart';
import 'package:flutter_tips/slidable/action_item_expander.dart';
import 'package:flutter_tips/slidable/action_layout_delegate.dart';
import 'package:flutter_tips/slidable/controller.dart';
import 'package:flutter_tips/slidable/models.dart';
import 'package:flutter_tips/slidable/slide_action_panel.dart';
import 'package:flutter_tips/slidable/slidable_panel.dart';

class SlidableExample extends StatefulWidget {
  const SlidableExample({super.key});

  @override
  State<SlidableExample> createState() => _SlidableExampleState();
}

class _SlidableExampleState extends State<SlidableExample> {
  final SlideController _slideController = SlideController();

  final ActionController _preActionController = ActionController();
  final ActionController _postActionController = ActionController();

  @override
  void dispose() {
    _preActionController.dispose();
    _postActionController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlidablePanel(
      axis: Axis.horizontal,
      controller: _slideController,
      preActionPanel: SlideActionPanel(
        slidePercent: _slideController.animationValue,
        controller: _preActionController,
        actionLayout: ActionLayout.spaceEvenly(ActionMotion.behind),
        actions: [
          ActionItem(
            flex: 2,
            child: InkWell(
              onTap: () {
                _preActionController.toggle(0);
              },
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.green),
                child: Center(
                  child: Text("Delete"),
                ),
              ),
            ),
          ),
          ActionItem(
            flex: 1,
            child: InkWell(
              onTap: () {
                _preActionController.toggle(1);
              },
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.red),
                child: Center(
                  child: Text("Delete"),
                ),
              ),
            ),
          ),
        ],
      ),
      postActionPanel: SlideActionPanel(
        slidePercent: _slideController.animationValue,
        controller: _postActionController,
        actionLayout: ActionLayout.spaceEvenly(ActionMotion.behind),
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
      ),
      child: InkWell(
        onTap: () {
          _slideController.dismiss(onDismissed: _resetActionItem);
        },
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

  void _resetActionItem() {
    _preActionController.reset();
    _postActionController.reset();
  }
}
