import 'package:flutter/material.dart';
import 'package:flutter_tips/positioned_list/custom_scroll_controller.dart';
import 'package:flutter_tips/positioned_list/observer/observer_proxy.dart';
import 'package:flutter_tips/positioned_list/positioned_list_delegate.dart';

import 'sliver_jump.dart';

class PageViewExample extends StatefulWidget {
  const PageViewExample({super.key});

  @override
  State<PageViewExample> createState() => _PageViewExampleState();
}

class _PageViewExampleState extends State<PageViewExample> {
  @override
  Widget build(BuildContext context) {
    return PageView.custom(
      childrenDelegate: IndexedChildBuilderDelegate(
        (context, index) => Card(
          child: Center(
            child: Text("Page $index"),
          ),
        ),
        childCount: 3,
      ),
    );
  }
}
