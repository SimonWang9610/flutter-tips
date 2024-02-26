import 'package:flutter/material.dart';

class MockPage extends StatefulWidget {
  final String name;
  final String url;
  const MockPage({super.key, required this.name, required this.url});

  @override
  State<MockPage> createState() => _MockPageState();
}

class _MockPageState extends State<MockPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Text(widget.url),
      ),
    );
  }
}
