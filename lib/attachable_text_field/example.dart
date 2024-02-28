import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tips/attachable_text_field/attachable.dart';
import 'package:flutter_tips/attachable_text_field/keyboard_sticky.dart';

class AttachableTextFieldExample extends StatefulWidget {
  const AttachableTextFieldExample({super.key});

  @override
  State<AttachableTextFieldExample> createState() =>
      _AttachableTextFieldExampleState();
}

class _AttachableTextFieldExampleState
    extends State<AttachableTextFieldExample> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Placeholder"),
        const Spacer(),
        const SizedBox(
          height: 50,
        ),
        KeyboardSticky.field(
          builder: (_, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            onTapOutside: (_) => focusNode.unfocus(),
            decoration: const InputDecoration(
              labelText: "Keyboard Sticky 1",
              border: OutlineInputBorder(),
            ),
          ),
          floatingBuilder: (context, controller, focusNode) {
            return Material(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Floating 1",
                  border: OutlineInputBorder(),
                ),
                child: ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (_, value, child) {
                    return Text(controller.text);
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(
          height: 50,
        ),

        KeyboardSticky.field(
          controller: _controller,
          focusNode: _focusNode,
          builder: (_, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onTapOutside: (_) {
                focusNode.unfocus();
              },
              decoration: const InputDecoration(
                labelText: "Custom Keyboard Sticky 1",
                border: OutlineInputBorder(),
              ),
            );
          },
          floatingBuilder: (_, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onTapOutside: (_) {
                focusNode.unfocus();
              },
              decoration: const InputDecoration(
                labelText: "Custom Floating 1",
                border: OutlineInputBorder(),
              ),
            );
          },
        ),

        // KeyboardSticky.field(
        //   builder: (_, controller, focusNode) => TextField(
        //     controller: controller,
        //     focusNode: focusNode,
        //     onTapOutside: (_) => focusNode.unfocus(),
        //     decoration: const InputDecoration(
        //       labelText: "Keyboard Sticky 2",
        //       border: OutlineInputBorder(),
        //     ),
        //   ),
        // ),
        const SizedBox(
          height: 50,
        ),
      ],
    );
  }
}

class PositionTextField extends StatefulWidget {
  final String label;
  const PositionTextField({
    super.key,
    required this.label,
  });

  @override
  State<PositionTextField> createState() => _PositionTextFieldState();
}

class _PositionTextFieldState extends State<PositionTextField>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focusNode,
      onTapOutside: (_) => _focusNode.unfocus(),
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
