import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/flow/delegates/circular_flow_delegate.dart';
import 'package:flutter_tips/flow/delegates/linear_flow_delegate.dart';
import 'models.dart';
import 'flow_button_bar.dart';

class FlowButtonBarExample extends StatefulWidget {
  const FlowButtonBarExample({Key? key}) : super(key: key);

  @override
  State<FlowButtonBarExample> createState() => _FlowButtonBarExampleState();
}

class _FlowButtonBarExampleState extends State<FlowButtonBarExample> {
  final List<FlowEntry> entries = [
    FlowEntry(
      onPressed: () {},
      builder: (toggleFlowButtonBar) {
        return IconButton(
          onPressed: toggleFlowButtonBar,
          icon: Icon(
            Icons.add,
            color: Colors.black,
          ),
        );
      },
    ),
    FlowEntry(
      onPressed: () {},
      builder: (toggleFlowButtonBar) {
        return IconButton(
          onPressed: toggleFlowButtonBar,
          icon: Icon(
            Icons.arrow_upward_rounded,
            color: Colors.black,
          ),
        );
      },
    ),
    FlowEntry(
      onPressed: () {},
      builder: (toggleFlowButtonBar) {
        return IconButton(
          onPressed: toggleFlowButtonBar,
          icon: Icon(
            Icons.arrow_downward_rounded,
            color: Colors.black,
          ),
        );
      },
    ),
    FlowEntry(
      onPressed: () {},
      builder: (toggleFlowButtonBar) {
        return IconButton(
          onPressed: toggleFlowButtonBar,
          icon: Icon(
            Icons.arrow_circle_left_rounded,
            color: Colors.black,
          ),
        );
      },
    ),
    FlowEntry(
      onPressed: () {},
      builder: (toggleFlowButtonBar) {
        return IconButton(
          onPressed: toggleFlowButtonBar,
          icon: Icon(
            Icons.arrow_circle_right_rounded,
            color: Colors.black,
          ),
        );
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flow Button Bar Example'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: LinearFlowButtonBarExample(entries: entries),
          ),
          Expanded(
            flex: 1,
            child: CircularFlowButtonBarExample(entries: entries),
          ),
        ],
      ),
    );
  }
}

class CircularFlowButtonBarExample extends StatefulWidget {
  final List<FlowEntry> entries;
  const CircularFlowButtonBarExample({
    Key? key,
    required this.entries,
  }) : super(key: key);

  @override
  State<CircularFlowButtonBarExample> createState() =>
      _CircularFlowButtonBarExampleState();
}

class _CircularFlowButtonBarExampleState
    extends State<CircularFlowButtonBarExample> {
  double radian = pi * 1.5;
  double radius = 20;
  double startRad = 0;

  CircularFlowDelegate createDelegate(Animation<double> animation) {
    return CircularFlowDelegate(
      animation: animation,
      radian: radian,
      radius: radius,
      startRad: startRad,
      alignment: Alignment.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Slider(
              label: "radius",
              value: radius,
              onChanged: (value) {
                radius = value;
                setState(() {});
              },
              divisions: 9,
              min: 20,
              max: 100,
            ),
            Slider(
              label: "radian",
              value: radian,
              onChanged: (value) {
                radian = value;
                setState(() {});
              },
              divisions: 9,
              min: 0,
              max: pi * 2,
            ),
            Slider(
              label: "start radian",
              value: startRad,
              onChanged: (value) {
                startRad = value;
                setState(() {});
              },
              divisions: 9,
              min: 0,
              max: pi * 2,
            ),
          ],
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all()),
            child: FlowButtonBar(
              entries: widget.entries,
              delegateBuilder: (Animation<double> animation) {
                return CircularFlowDelegate(
                  animation: animation,
                  radian: radian,
                  radius: radius,
                  startRad: startRad,
                  alignment: Alignment.center,
                );
              },
            ),
          ),
        )
      ],
    );
  }
}

class LinearFlowButtonBarExample extends StatefulWidget {
  final List<FlowEntry> entries;
  const LinearFlowButtonBarExample({
    Key? key,
    required this.entries,
  }) : super(key: key);

  @override
  State<LinearFlowButtonBarExample> createState() =>
      _LinearFlowButtonBarExampleState();
}

class _LinearFlowButtonBarExampleState
    extends State<LinearFlowButtonBarExample> {
  double buttonGap = 15;
  FlowDirection direction = FlowDirection.right;
  Alignment alignment = Alignment.center;

  LinearFlowDelegate createDelegate(Animation<double> animation) {
    return LinearFlowDelegate(
      animation: animation,
      buttonGap: buttonGap,
      direction: direction,
      alignment: alignment,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Slider(
              label: "button gap",
              divisions: 9,
              value: buttonGap,
              onChanged: (value) {
                buttonGap = value;
                setState(() {});
              },
              min: 0,
              max: 40,
            ),
            TextButton(
              onPressed: () {
                direction = FlowDirection.right;
                setState(() {});
              },
              child: const Text("right direction"),
            ),
            TextButton(
              onPressed: () {
                direction = FlowDirection.left;
                setState(() {});
              },
              child: const Text("left direction"),
            ),
            TextButton(
              onPressed: () {
                direction = FlowDirection.up;
                setState(() {});
              },
              child: const Text("up direction"),
            ),
            TextButton(
              onPressed: () {
                direction = FlowDirection.down;
                setState(() {});
              },
              child: const Text("down direction"),
            ),
          ],
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all()),
            child: FlowButtonBar(
              entries: widget.entries,
              clipBehavior: Clip.none,
              // delegateBuilder: createDelegate,
              delegateBuilder: (animation) {
                return LinearFlowDelegate(
                  animation: animation,
                  buttonGap: buttonGap,
                  direction: direction,
                  alignment: alignment,
                );
              },
            ),
          ),
        )
      ],
    );
  }
}
