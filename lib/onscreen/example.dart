import 'dart:math';

import 'package:flutter/material.dart' hide Placeholder;
import 'package:flutter_tips/onscreen/background.dart';
import 'package:flutter_tips/onscreen/widget.dart';
import 'package:flutter_tips/onscreen/painter.dart';

class OnscreenBoardExample extends StatefulWidget {
  const OnscreenBoardExample({super.key});

  @override
  State<OnscreenBoardExample> createState() => _OnscreenBoardExampleState();
}

class _OnscreenBoardExampleState extends State<OnscreenBoardExample> {
  final Map<OnscreenPosition, OnscreenElement> _elements = {
    OnscreenPosition.bottomCenter: PartyBanner("A", "We are the best"),
    OnscreenPosition.topLeft: PartyLogo("https://example.com/logo.png"),
    OnscreenPosition.topCenter: PartyBanner("B", "A Party Banner")
  };

  final OnscreenFocusNode _focusNode = OnscreenFocusNode(
    border: const PaintConfiguration(color: Colors.red, width: 3),
    // dashLength: 5,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OnscreenBoard.builder(
          builder: _buildElement,
          margin: const EdgeInsets.all(2),
          padding: const OnscreenPadding.symmetric(
            vertical: 0.1,
            horizontal: 0.1,
          ),
          preferredSize: const Size(640, 480),
          focusNode: _focusNode,
          backgroundPainter: OnscreenBackgroundPainter(
            dashLength: 10,
            border: const PaintConfiguration(color: Colors.black, width: 1),
            dash: const PaintConfiguration(color: Colors.green, width: 1),
          ),
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: _focusNode,
          builder: (context, child) {
            final desc = _focusNode.focusedPosition != null
                ? "${_focusNode.focusedPosition}: ${_focusNode.focusedElement}"
                : "Not selected";

            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _focusNode.focusedPosition != null
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

  Widget _buildElement(OnscreenPosition position) {
    final ele = _elements[position];

    final (desc, color) = switch (ele) {
      PartyBanner(slogan: final s) => (s, Colors.green),
      PartyLogo() => ("LOGO", Colors.yellow),
      _ => ("None", Colors.black),
    };

    return GestureDetector(
      onTap: () {
        if (_focusNode.focusedPosition == position) {
          _focusNode.unfocus();
        } else {
          _focusNode.focus(position, ele);
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
  }

  void _randomAdd() {
    final i = Random().nextInt(OnscreenPosition.values.length);
    final pos = OnscreenPosition.values[i];
    final ele = Random().nextBool()
        ? PartyBanner("Random $i", "Slogan $i")
        : PartyLogo("https://example.com/random-$i.png");

    if (_elements.containsKey(pos)) {
      _elements.remove(pos);
    } else {
      _elements[pos] = ele;
    }

    setState(() {});
  }
}
