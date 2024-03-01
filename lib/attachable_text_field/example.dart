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
  final TextEditingController _controllerForOriginal = TextEditingController();
  final TextEditingController _controllerForFloating = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _controllerForOriginal.dispose();
    _controllerForFloating.dispose();
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
        KeyboardSticky.single(
          controller: _controllerForOriginal,
          builder: (context, controller, field) {
            return Material(
              elevation: 4,
              child: field,
            );
          },
          fieldBuilder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onTapOutside: (_) {
                focusNode.unfocus();
              },
              decoration: const InputDecoration(
                labelText: "Only original",
                border: OutlineInputBorder(),
              ),
            );
          },
          floatingBuilder: (context, controller, field) {
            return InputDecorator(
              decoration: const InputDecoration(
                labelText: "Floating for Single Original",
                border: OutlineInputBorder(),
              ),
              child: ListenableBuilder(
                listenable: _controllerForOriginal,
                builder: (_, __) => Text(_controllerForOriginal.text),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        KeyboardSticky.single(
          controller: _controllerForFloating,
          forFloating: true,
          builder: (context, controller, field) {
            return GestureDetector(
              onTap: () => controller.showFloating(),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Original for Single Floating",
                  border: OutlineInputBorder(),
                ),
                child: ListenableBuilder(
                  listenable: _controllerForFloating,
                  builder: (_, __) => Text(_controllerForFloating.text),
                ),
              ),
            );
          },
          fieldBuilder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onTapOutside: (_) {
                focusNode.unfocus();
              },
              decoration: const InputDecoration(
                labelText: "Only Floating",
                border: OutlineInputBorder(),
              ),
            );
          },
          floatingBuilder: (context, controller, field) {
            return field!;
          },
        ),
        const SizedBox(height: 20),
        KeyboardSticky.both(
          builder: (_, controller, field) {
            return Material(
              elevation: 4,
              child: field,
            );
          },
          fieldBuilder: (inner, controller, focusNode) {
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
          floatingFieldBuilder: (inner, controller, focusNode) {
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
        const SizedBox(height: 20),
        const StickyDropdownExample(),
        const SizedBox(height: 20),
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
    return KeyboardSticky.both(
      fieldBuilder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
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
      builder: (context, _, field) {
        return Dropdown<String>.list(
          ///! if enabled, the dropdown menu would first insert itself into the overlay,
          ///! consequently, it would effect the visibility calculation of the dropdown menu during resizing.
          ///! no effect if we o not need to resize the dropdown menu to avoid the bottom insets.
          enabled: false,
          controller: _controller,
          menuPosition: const DropdownMenuPosition(
            targetAnchor: Alignment.topLeft,
            anchor: Alignment.bottomLeft,
            offset: Offset(0, -5),
          ),
          menuConstraints: const BoxConstraints(
            maxHeight: 200,
          ),
          menuDecoration: BoxDecoration(
            color: Colors.yellow,
            border: Border.all(color: Colors.black12),
          ),
          builder: (_) => Material(
            elevation: 4,
            child: field,
          ),
          itemBuilder: (_, item) => GestureDetector(
            onTap: () {
              _controller.select(item.value);
              field?.controller?.text = item.value;
              field?.focusNode?.unfocus();
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
