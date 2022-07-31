import 'package:flutter/material.dart';
import 'package:flutter_tips/blocks/list_block.dart';
import 'package:flutter_tips/blocks/list_data.dart';
import 'package:flutter_tips/carousel/example.dart';
import 'package:flutter_tips/flow/example.dart';
import 'package:flutter_tips/gallery/example.dart';
import 'package:flutter_tips/list/custom_grid_list.dart';
import 'package:flutter_tips/list/example.dart';
import 'package:flutter_tips/overlay/overlay_example.dart';
import 'package:flutter_tips/planet/example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const GridGalleryExample(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  double shift = 0.0;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 20,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all()),
            child: SizedBox(
              width: 100,
              child: Column(
                children: [
                  GestureTest(
                    label: 'first',
                    onTap: _translate,
                  ),
                  Transform.translate(
                    offset: Offset(shift, shift),
                    child: GestureTest(
                      label: 'second',
                      onTap: _translate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          shift += 10.0;

          setState(() {});
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _translate() {
    shift += 5.0;
    setState(() {});
  }
}

class DragTest extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const DragTest({
    Key? key,
    required this.label,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: DragTarget<String>(
        builder: (_, __, ___) {
          return Draggable<String>(
            data: label,
            feedback: Text('Dragging $label'),
            child: SizedBox.square(
              dimension: 50,
              child: Text(label),
            ),
          );
        },
        onAccept: (_) {
          onTap?.call();
        },
      ),
    );
  }
}

class GestureTest extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const GestureTest({
    Key? key,
    required this.label,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all()),
      child: SizedBox.square(
        dimension: 50,
        child: GestureDetector(
          onTap: () {
            print('tap: $label');
            onTap?.call();
          },
          child: Text(label),
        ),
      ),
    );
  }
}
