import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/onscreen/models.dart';
import 'package:flutter_tips/onscreen/widget.dart';
import 'package:flutter_tips/onscreen/painter.dart';

class OnscreenBoardExample extends StatefulWidget {
  const OnscreenBoardExample({super.key});

  @override
  State<OnscreenBoardExample> createState() => _OnscreenBoardExampleState();
}

class _OnscreenBoardExampleState extends State<OnscreenBoardExample> {
  final OnscreenController _controller = OnscreenController(
    elements: {
      OnscreenPosition.bottomCenter: PartyBanner("A", "We are the best"),
      OnscreenPosition.topLeft: PartyLogo("https://example.com/logo.png"),
      OnscreenPosition.topCenter: PartyBanner("B", "A Party Banner")
    },
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: OnscreenBoard(
            controller: _controller,
            builder: (ctx, position) {
              final ele = _controller.getElement(position);

              final (desc, color) = switch (ele) {
                PartyBanner(slogan: final s) => (s, Colors.green),
                PartyLogo() => ("LOGO", Colors.yellow),
                _ => ("None", Colors.black),
              };
              return InkWell(
                onTap: () {
                  if (_controller.focusedPosition == position) {
                    _controller.unfocus();
                  } else {
                    _controller.focus(position);
                  }
                },
                child: Container(
                  color: color,
                  child: Center(
                    child: Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
            margin: const EdgeInsets.all(5),
            padding: const OnscreenPadding.symmetric(
              vertical: 0.1,
              horizontal: 0.1,
            ),
            // preferredSize: const Size(640, 480),
            painter: OnscreenPainter(
              border: const PaintConfiguration(
                color: Colors.black,
                width: 2,
                // dash: 5,
              ),
              lines: const PaintConfiguration(
                color: Colors.green,
                width: 1,
                dash: 5,
              ),
              focusedBorder: const PaintConfiguration(
                color: Colors.red,
                width: 3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final desc = _controller.focusedPosition != null
                ? "${_controller.focusedPosition}: ${_controller.focusedElement}"
                : "Not selected";

            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _controller.focusedPosition != null
                      ? Colors.green
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _randomAdd,
          child: const Text("Randomize"),
        ),
      ],
    );
  }

  void _randomAdd() {
    final i = Random().nextInt(OnscreenPosition.values.length);
    final pos = OnscreenPosition.values[i];
    final ele = Random().nextBool()
        ? PartyBanner("Random $i", "Slogan $i")
        : PartyLogo("https://example.com/random-$i.png");

    if (_controller.hasElement(pos)) {
      _controller.remove(pos);
    } else {
      _controller.update(pos, ele);
    }

    // if (_controller.hasFocus) {
    //   _controller.remove(_controller.focusedPosition!);
    // }

    // _controller.remove(pos);

    // if (_controller.hasFocus) {
    //   _controller.update(_controller.focusedPosition!, ele);
    // }
  }
}
