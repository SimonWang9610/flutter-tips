import 'package:flutter/material.dart';
import 'floating_buttons.dart';

class FlowButtonsExample extends StatefulWidget {
  const FlowButtonsExample({Key? key}) : super(key: key);

  @override
  State<FlowButtonsExample> createState() => _FlowButtonsExampleState();
}

class _FlowButtonsExampleState extends State<FlowButtonsExample> {
  final GlobalKey<FlowButtonsState> flowKey = GlobalKey<FlowButtonsState>();
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('text'),
            SizedBox(
              width: 400,
              height: 400,
              child: FlowButtons(
                entries: entries,
              ),
            ),
            Expanded(
              child: FlowButtons(
                alignment: Alignment(0, 0),
                // direction: FlowDirection.down,
                entries: entries,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          flowKey.currentState?.activateButton();
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
