import 'package:flutter/material.dart';
import 'package:flutter_tips/positioned_list/example/custom_view_example.dart';
import 'package:flutter_tips/positioned_list/example/grid_example.dart';
import 'package:flutter_tips/positioned_list/example/list_example.dart';
import 'package:flutter_tips/positioned_list/observer/observer_proxy.dart';
import 'positioned_list/positioned_list_delegate.dart';
import 'positioned_list/custom_scroll_controller.dart';

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

class PositionedSliverExample extends StatelessWidget {
  const PositionedSliverExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            OutlinedButton(
              onPressed: () {
                context.push(
                  const PositionedListExample(),
                );
              },
              child: const Text("List Example"),
            ),
            OutlinedButton(
              onPressed: () {
                context.push(const PositionedGridExample());
              },
              child: const Text("Grid Example"),
            ),
            OutlinedButton(
              onPressed: () {
                context.push(const CustomViewExample());
              },
              child: const Text("CustomScrollView Example"),
            ),
          ],
        ),
      ),
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
