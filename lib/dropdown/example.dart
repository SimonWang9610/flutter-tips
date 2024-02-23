import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tips/dropdown/dropdown.dart';
import 'package:flutter_tips/dropdown/models.dart';

class DropdownExample extends StatefulWidget {
  const DropdownExample({super.key});

  @override
  State<DropdownExample> createState() => _DropdownExampleState();
}

class _DropdownExampleState extends State<DropdownExample> {
  final DropdownController<String> _controller = DropdownController<String>(
    items: [
      "Item 1",
      "Item 2",
      "Item 3",
      "Item 4",
    ],
  );

  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: Text("Another Page"),
                    ),
                    body: Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: DropdownExample(),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Text("go another page"),
          ),
          const SizedBox(height: 30),
          Dropdown<String>(
            controller: _controller,
            builder: (_, selected) => Container(
              width: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(selected ?? "Select Item"),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            // builder: (_, selected) => SizedBox(
            //   width: 150,
            //   child: TextField(
            //     controller: _textController,
            //     decoration: InputDecoration(
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(4),
            //       ),
            //       hintText: "Search Item",
            //     ),
            //     onChanged: (_) => _search(),
            //   ),
            // ),
            // menuDecoration: BoxDecoration(
            //   border: Border.all(color: Colors.grey),
            //   borderRadius: BorderRadius.circular(4),
            // ),
            // targetAnchor: Alignment.topLeft,
            // anchor: Alignment.bottomLeft,

            menuPosition: DropdownMenuPosition(),
            menuConstraints: const BoxConstraints(
              maxHeight: 150,
            ),
            itemBuilder: (_, item) => GestureDetector(
              onTap: () {
                if (item == "Item 1") {
                  _controller.loadMore(
                    () => Future.delayed(
                      const Duration(seconds: 1),
                      () => [
                        "Item 9",
                        "Item 10",
                        "Item 11",
                        "Item 12",
                      ],
                    ),
                  );
                } else {
                  _controller.select(item);
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(item),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 2000,
          ),
        ],
      ),
    );
  }

  Timer? _debounce;

  void _search() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_textController.text.isEmpty) {
        _controller.restore();
      } else {
        _controller.search(
          (query) => Future.delayed(
            const Duration(seconds: 1),
            () => [
              "$query 1",
              "$query 2",
              "$query 3",
              "$query 4",
            ],
          ),
          _textController.text,
        );
      }
    });
  }
}
