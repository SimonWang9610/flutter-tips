import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/positioned_list/positioned_list_delegate.dart';

import '../observer/indexed_scroll_controller.dart';

import 'sliver_jump.dart';

class PositionedListExample extends StatefulWidget {
  const PositionedListExample({super.key});

  @override
  State<PositionedListExample> createState() => _PositionedListExampleState();
}

class _PositionedListExampleState extends State<PositionedListExample> {
  int _itemCount = 30;

  final IndexedScrollController _controller =
      IndexedScrollController.singleObserver();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("List View Example"),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: _addItem,
                child: const Text("Add Item"),
              ),
              OutlinedButton(
                onPressed: _deleteItem,
                child: const Text("Delete Item"),
              ),
              OutlinedButton(
                onPressed: _goStart,
                child: const Text("Scroll to edge"),
              ),
            ],
          ),
          SliverJumpWidget(
            label: "without animation",
            onJump: (index) {
              _controller.jumpToIndex(index);
            },
          ),
          SliverJumpWidget(
            label: "animation",
            onJump: (index) {
              _controller.animateToIndex(
                index,
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastLinearToSlowEaseIn,
              );
            },
          ),
          Expanded(
            child: ListView.custom(
              controller: _controller,
              childrenDelegate: IndexedChildBuilderDelegate(
                (context, index) => ListTile(
                  key: ValueKey<int>(index),
                  leading: const CircleAvatar(
                    child: Text("L"),
                  ),
                  title: Text("Positioned List Example $index"),
                ),
                childCount: _itemCount,
                observer:
                    _controller.createOrObtainObserver(itemCount: _itemCount),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _goStart() {
    _controller.showInViewport();
  }

  void _addItem() {
    _itemCount++;
    setState(() {});
  }

  void _deleteItem() {
    _itemCount = max(--_itemCount, 0);
    setState(() {});
  }
}
