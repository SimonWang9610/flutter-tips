import 'package:flutter/material.dart';

class ListPhysicsExample extends StatefulWidget {
  const ListPhysicsExample({super.key});

  @override
  State<ListPhysicsExample> createState() => _ListPhysicsExampleState();
}

class _ListPhysicsExampleState extends State<ListPhysicsExample> {
  final ScrollController _controller = ScrollController();
  final List<int> _items = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("post frame callback phase");

      _controller.jumpTo(_controller.position.maxScrollExtent);
    });
  }

  void _add() {
    setState(() {
      _items.add(_items.length);
    });
  }

  void _delete() {
    setState(() {
      _items.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _controller,
              physics: const ListPhysics(),
              itemCount: _items.length,
              itemBuilder: (_, index) => ListTile(
                title: Text("Item ${_items[index]}"),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              OutlinedButton(onPressed: _add, child: const Icon(Icons.add)),
              OutlinedButton(
                  onPressed: _delete, child: const Icon(Icons.delete)),
            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ListPhysics extends ScrollPhysics {
  const ListPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  ListPhysics applyTo(ScrollPhysics? ancestor) {
    return ListPhysics(parent: buildParent(ancestor));
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    print("adjustPositionForNewDimensions");
    final diff = newPosition.maxScrollExtent - oldPosition.maxScrollExtent;

    final oldPixels = oldPosition.pixels;
    final oldMax = oldPosition.maxScrollExtent;

    final shouldAdjust = (oldPixels >= oldMax) && diff > 0;

    final position = super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );

    if (shouldAdjust) {
      return position + diff;
    } else {
      return position;
    }
  }
}
