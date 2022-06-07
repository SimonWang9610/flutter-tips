import 'package:flutter/material.dart';
import 'package:flutter_tips/overlay/overlay.dart';

class OverlayExample extends StatefulWidget {
  const OverlayExample({Key? key}) : super(key: key);

  @override
  State<OverlayExample> createState() => _OverlayExampleState();
}

class _OverlayExampleState extends State<OverlayExample> {
  final CustomAnimatedOverlay overlay = CustomAnimatedOverlay(
    const Duration(
      milliseconds: 200,
    ),
  );

  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Overlay'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_count',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOverlay,
        tooltip: 'Add Overlay',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _addOverlay() {
    final child = DraggableCard(
      overlayController: overlay,
      onTap: _incrementCount,
    );

    overlay.insert(context, child: child);
  }

  void _incrementCount() {
    _count++;
    setState(() {});
  }
}

class DraggableCard extends StatelessWidget {
  final VoidCallback? onTap;
  final CustomAnimatedOverlay overlayController;
  const DraggableCard({
    Key? key,
    this.onTap,
    required this.overlayController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: onTap,
      child: const Card(
        color: Colors.yellow,
        child: Text('Card'),
      ),
      onPanUpdate: (details) {
        overlayController.alignChildTo(details.globalPosition, size * 0.5);
      },
      onPanEnd: (_) {
        overlayController.alignToScreenEdge();
      },
    );
  }
}
