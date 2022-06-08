import 'package:flutter/material.dart';
import 'package:flutter_tips/list/custom_animated_list.dart';

class AnimatedListExample extends StatefulWidget {
  const AnimatedListExample({Key? key}) : super(key: key);

  @override
  State<AnimatedListExample> createState() => _AnimatedListExampleState();
}

class _AnimatedListExampleState extends State<AnimatedListExample> {
  final GlobalKey<CustomAnimatedListState> _listKey =
      GlobalKey<CustomAnimatedListState>();

  final ScrollController scrollController = ScrollController();
  final List<Widget> children = [];

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Animated List'),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: CustomAnimatedList(
                key: _listKey,
                itemBuilder: (_, index) => children[index],
                transitionBuilder: (_, animation, index, child) {
                  return ScaleTransition(
                    key: ValueKey(index),
                    scale: animation,
                    child: child,
                  );
                },
                separatedBuilder: (_, __) => const Divider(
                  color: Colors.black,
                ),
                initWithSeparator: true,
                itemIndexPolicy: ItemIndexPolicy.before,
                findChildIndex: (key) {
                  if (key is ValueKey<int>) {
                    return key.value;
                  }
                },
                curve: Curves.bounceInOut,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {
                    children.add(
                      CardItem(text: '${children.length}'),
                    );
                    _listKey.currentState?.animateTo(
                      children.length - 1,
                      ListOperation.insert,
                    );
                  },
                  icon: const Icon(
                    Icons.add,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    children.removeLast();
                    _listKey.currentState?.animateTo(
                      children.length - 1,
                      ListOperation.remove,
                    );
                  },
                  icon: const Icon(
                    Icons.minimize,
                  ),
                ),
                IconButton(
                    onPressed: () {
                      if (children.length > 2) {
                        final last = children.removeLast();
                        children.insert(0, last);
                        _listKey.currentState?.animateTo(
                          0,
                          ListOperation.reorder,
                        );
                      }
                    },
                    icon: Icon(
                      Icons.swap_vert_circle,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  final String text;
  const CardItem({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Card(
        color: Colors.yellow,
        child: SizedBox(
          width: 100,
          height: 50,
          child: Text(text),
        ),
      ),
    );
  }
}
