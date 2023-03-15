import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tips/positioned_list/example/custom_view_example.dart';
import 'package:flutter_tips/positioned_list/example/grid_example.dart';
import 'package:flutter_tips/positioned_list/example/list_example.dart';
import 'package:flutter_tips/positioned_list/indexed_observer_proxy.dart';

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
      // home: const MyHomePage(
      //   title: 'my home page',
      // ),
      home: const MyHomePage(title: "List Example"),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: const PositionedSliverExample(),
    );
  }
}

class PositionedSliverExample extends StatefulWidget {
  const PositionedSliverExample({super.key});

  @override
  State<PositionedSliverExample> createState() =>
      _PositionedSliverExampleState();
}

class _PositionedSliverExampleState extends State<PositionedSliverExample> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _controller.jumpTo(1500);
      print("current: ${_controller.position.pixels}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(border: Border.all()),
            child: SizedBox(
              height: 100,
              child: Text("Header"),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _controller,
              child: const ScrollableColumn(),
            ),
          ),
        ],
      ),
    );
  }
}

class ScrollableColumn extends StatelessWidget {
  const ScrollableColumn({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final render = context.findRenderObject()!;

      final viewport = RenderAbstractViewport.of(render);

      final revealedOffset = viewport.getOffsetToReveal(render, 0.0);
      print(revealedOffset);
    });

    return Column(
      children: [
        for (int i = 0; i < 30; i++)
          IndexedObserverProxy(
            index: i,
            child: SizedBox(
              height: 150,
              child: Center(
                child: Text("Child $i"),
              ),
            ),
          )
      ],
    );
  }
}

extension Navigation on BuildContext {
  void push(Widget page) {
    Navigator.of(this).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}
