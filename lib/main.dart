import 'package:flutter/material.dart';
import 'package:flutter_tips/blocks/list_block.dart';
import 'package:flutter_tips/blocks/list_data.dart';
import 'package:flutter_tips/carousel/example.dart';
import 'package:flutter_tips/exercises/example.dart';
import 'package:flutter_tips/flow/example.dart';
import 'package:flutter_tips/gallery/example.dart';
import 'package:flutter_tips/graph/clip_example.dart';
import 'package:flutter_tips/graph/scrollable_example.dart';
import 'package:flutter_tips/graph/transform_exmaple.dart';
import 'package:flutter_tips/list/custom_grid_list.dart';
import 'package:flutter_tips/list/example.dart';
import 'package:flutter_tips/navigation/example.dart';
import 'package:flutter_tips/overlay/overlay_example.dart';
import 'package:flutter_tips/planet/example.dart';
import 'package:flutter_tips/tree/minimal_tree_example.dart';

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
      home: const MyHomePage(
        title: 'my home page',
      ),
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
  bool _showFirst = true;

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ClipTreeViewExample(),
                  ),
                );
              },
              child: const Text("Clip tree view"),
            ),
            const SizedBox(
              height: 40,
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TransformTreeViewExample(),
                  ),
                );
              },
              child: const Text("transform tree view"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ScrollableTreeViewExample(),
                  ),
                );
              },
              child: const Text("scrollable tree view"),
            )
          ],
        ),
      ),
      // body: Center(
      //   child: SizedBox.square(
      //     dimension: 100,
      //     child: MinimalTreeExample(),
      //   ),
      // ),
    );
  }
}

class ScaledScrollView extends StatefulWidget {
  const ScaledScrollView({Key? key}) : super(key: key);

  @override
  State<ScaledScrollView> createState() => _ScaledScrollViewState();
}

class _ScaledScrollViewState extends State<ScaledScrollView> {
  final List<Widget> children = List.generate(
    100,
    (index) => Text(
      "item $index",
      textAlign: TextAlign.center,
    ),
  );

  double _scaleY = 1.0;
  double _scaleX = 1.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all()),
      child: SingleChildScrollView(
        child: GestureDetector(
          onScaleStart: (details) {},
          onScaleUpdate: (details) {
            final vertical = details.verticalScale;
            final horizontal = details.horizontalScale;
            print("vertical: $vertical, horizontal: $horizontal");
            _scaleX = horizontal;
            _scaleY = vertical;
            setState(() {});
          },
          onScaleEnd: (details) {},
          child: Transform.scale(
            scaleX: _scaleX,
            scaleY: _scaleY,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
