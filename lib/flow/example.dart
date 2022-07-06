import 'package:flutter/material.dart';
import 'models.dart';
import 'flow_buttons.dart';

class FlowButtonsExample extends StatefulWidget {
  const FlowButtonsExample({Key? key}) : super(key: key);

  @override
  State<FlowButtonsExample> createState() => _FlowButtonsExampleState();
}

class _FlowButtonsExampleState extends State<FlowButtonsExample> {
  final List<FlowEntry> entries = [
    FlowEntry(
      child: Icon(
        Icons.abc,
        color: Colors.black,
      ),
      onPressed: () {},
    ),
    FlowEntry(
      child: Icon(
        Icons.ac_unit_outlined,
        color: Colors.black,
      ),
      onPressed: () {},
    ),
    FlowEntry(
      child: Icon(
        Icons.accessible,
        color: Colors.black,
      ),
      onPressed: () {},
    ),
    FlowEntry(
      child: Icon(
        Icons.access_alarm,
        color: Colors.black,
      ),
      onPressed: () {},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flow Buttons Example'),
      ),
      body: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          const Text('Stack'),
          Align(
            alignment: Alignment.centerRight,
            child: FlowButtons(
              entries: entries,
              type: FlowType.circular,
              params: CircularFlowParams(
                angle: 180,
                radius: 100,
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: ConstrainedBox(
              constraints: const BoxConstraints.tightFor(
                width: 200,
                height: 100,
              ),
              child: FlowButtons(
                entries: entries,
                type: FlowType.linear,
                params: LinearFlowParams(
                  direction: FlowDirection.left,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
