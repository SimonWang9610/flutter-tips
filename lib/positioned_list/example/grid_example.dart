import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/positioned_list/indexed_child_delegate.dart';
import '../observer/indexed_scroll_controller.dart';

import 'sliver_jump.dart';

class PositionedGridExample extends StatefulWidget {
  const PositionedGridExample({super.key});

  @override
  State<PositionedGridExample> createState() => _PositionedGridExampleState();
}

class _PositionedGridExampleState extends State<PositionedGridExample> {
  int _itemCount = 30;

  final IndexedScrollController _controller =
      IndexedScrollController.singleObserver();

  final String observerKey = "grid";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Post frame callback");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Grid View Example"),
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
            label: observerKey,
            onJump: (index) => _controller.jumpToIndex(
              index,
            ),
          ),
          SliverJumpWidget(
            label: observerKey,
            onJump: (index) {
              _controller.animateToIndex(
                index,
                duration: const Duration(milliseconds: 200),
                curve: Curves.bounceInOut,
              );

              _controller.animateToIndex(
                _itemCount - index,
                duration: const Duration(milliseconds: 200),
                curve: Curves.bounceInOut,
              );
            },
          ),
          Expanded(
            child: GridView.custom(
              controller: _controller,
              childrenDelegate: IndexedChildBuilderDelegate(
                (context, index) => ListTile(
                  key: ValueKey<int>(index),
                  leading: const CircleAvatar(
                    child: Text("G"),
                  ),
                  title: Text("Positioned Grid Example $index"),
                ),
                childCount: _itemCount,
                observer:
                    _controller.createOrObtainObserver(itemCount: _itemCount),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
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
  }
}
