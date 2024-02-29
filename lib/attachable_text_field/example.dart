import 'package:flutter/material.dart';
import 'package:flutter_tips/attachable_text_field/keyboard_sticky.dart';
import 'package:flutter_tips/dropdown/controller.dart';
import 'package:flutter_tips/dropdown/dropdown.dart';
import 'package:flutter_tips/dropdown/models.dart';

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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildColumn(),
    );
  }

  Widget _buildColumn() {
    return Column(
      children: [
        const Text("Placeholder"),
        const Spacer(),
        // const SizedBox(
        //   height: 400,
        // ),
        KeyboardSticky.field(
          controller: _controller,
          focusNode: _focusNode,
          builder: (inner, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onTapOutside: (_) {
                focusNode.unfocus();
              },
              decoration: const InputDecoration(
                labelText: "Keyboard Sticky 2",
                border: OutlineInputBorder(),
              ),
            );
          },
          floatingBuilder: (inner, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onTapOutside: (_) {
                focusNode.unfocus();
              },
              decoration: const InputDecoration(
                labelText: "Floating 2",
                border: OutlineInputBorder(),
              ),
            );
          },
        ),
        const SizedBox(
          height: 50,
        ),
        const StickyDropdownExample(),
        const SizedBox(height: 50),
      ],
    );
  }
}

class StickyDropdownExample extends StatefulWidget {
  const StickyDropdownExample({super.key});

  @override
  State<StickyDropdownExample> createState() => _StickyDropdownExampleState();
}

class _StickyDropdownExampleState extends State<StickyDropdownExample> {
  final DropdownController<String> _controller = DropdownController.single(
    items: List.generate(
      15,
      (i) => DropdownItem(value: "Item $i"),
    ),
  );

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardSticky.field(
      // builder: (inner, textController, focusNode) {
      //   final stickyController = KeyboardSticky.of(inner);

      //   return GestureDetector(
      //     onTap: () => stickyController?.showFloating(),
      //     child: InputDecorator(
      //       decoration: const InputDecoration(
      //         labelText: "Sticky Dropdown",
      //         border: OutlineInputBorder(),
      //       ),
      //       child: ListenableBuilder(
      //         listenable: _controller,
      //         builder: (_, child) {
      //           return Text(_controller.selectedItem ?? "");
      //         },
      //       ),
      //     ),
      //   );
      // },
      //! DropdownController cannot switch back to the previous attached state if it's detached from this current state
      // ! changes the ingle attache states into a stack of attached states, detaching the top state will reveal the previous state
      builder: (_, textController, focusNode) {
        return Dropdown<String>.list(
          ///! if enabled, the dropdown menu would first insert itself into the overlay,
          ///! consequently, it would effect the visibility calculation of the dropdown menu during resizing.
          ///! no effect if we o not need to resize the dropdown menu to avoid the bottom insets.
          // enabled: false,
          menuPosition: const DropdownMenuPosition(
            targetAnchor: Alignment.topLeft,
            anchor: Alignment.bottomLeft,
            offset: Offset(0, -5),
          ),
          menuConstraints: const BoxConstraints(
            maxHeight: 200,
          ),
          menuDecoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
          controller: _controller,
          builder: (_) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              onChanged: (value) {
                if (!_controller.isOpen) {
                  _controller.open();
                }

                if (value.isEmpty) {
                  _controller.restore();
                } else {
                  _controller.search(
                    value,
                    matcher: (query, ele) => ele.contains(query),
                  );
                }
              },
              decoration: const InputDecoration(
                labelText: "Sticky Dropdown",
                border: OutlineInputBorder(),
              ),
            );
          },
          itemBuilder: (_, item) => GestureDetector(
            onTap: () {
              _controller.select(item.value);
              textController.text = item.value;
              focusNode.unfocus();
            },
            child: Card(
              margin: const EdgeInsets.all(8),
              color: item.selected ? Colors.green : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(item.value),
            ),
          ),
        );
      },
    );
  }
}
