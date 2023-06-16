import 'package:flutter/material.dart';
import 'package:flutter_tips/slidable/render.dart';
import 'package:flutter_tips/slidable/widget.dart';

class SlidableExample extends StatefulWidget {
  const SlidableExample({super.key});

  @override
  State<SlidableExample> createState() => _SlidableExampleState();
}

class _SlidableExampleState extends State<SlidableExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..addStatusListener((status) {
      print(status);
    });

  final leftToRightActions = const [
    SlideActionWidget(
        child: DecoratedBox(
      decoration: BoxDecoration(color: Colors.red),
      child: Center(
        child: Text("Delete"),
      ),
    )),
    SlideActionWidget(child: Icon(Icons.add))
  ];

  final rightToleftActions = const [
    SlideActionWidget(child: Icon(Icons.edit)),
    SlideActionWidget(child: Icon(Icons.edit))
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_controller.status == AnimationStatus.completed) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
      },
      // onHorizontalDragUpdate: (details) {
      //   final delta = details.delta;

      //   if (delta.dx > 0) {
      //     _controller.forward();
      //   } else {
      //     _controller.reverse();
      //   }
      // },
      // onHorizontalDragEnd: (details) {
      //   if (_controller.status == AnimationStatus.completed) {
      //     _controller.reverse();
      //   } else {
      //     _controller.forward();
      //   }
      // },
      child: SlidablePanel(
        controller: CurvedAnimation(
            parent: _controller,
            curve: Curves.linearToEaseOut,
            reverseCurve: Curves.easeInToLinear),
        direction: SlideDirection.rightToLeft,
        actions: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.green,
              border: Border.all(),
            ),
            child: Center(
              child: Text("Main Child"),
            ),
          ),
          ...leftToRightActions,
        ],
      ),
    );
  }
}
