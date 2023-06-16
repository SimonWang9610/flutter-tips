import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tips/indicator/linear.dart';
import 'package:flutter_tips/slidable/example.dart';

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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: "List Example"),
      home: const MyHomePage(title: "timezone example"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? _timer;

  double _current = 0;

  double total = 10;
  @override
  void initState() {
    super.initState();

    _toggleTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_timer?.isActive == true) {
      _timer?.cancel();
      _timer = null;
      _current = 0;
      setState(() {});
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _current += 1;

        if (_current > total) {
          _current = 0;
        }

        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: const Center(
        child: SlidableExample(),
      ),
    );
  }
}
