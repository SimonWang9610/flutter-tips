import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tips/blocks/list_data.dart';

typedef BlockBuilder = Widget Function(ListBlockData);

Widget defaultListBlockBuilder(ListBlockData data) => ListBlockWidget(
      key: ValueKey(data.id),
      data: data,
    );

class ListBlock {
  final BlockBuilder builder;
  final ListBlockData data;

  ListBlock({
    required this.data,
  }) : builder = defaultListBlockBuilder;

  Widget build() => builder(data);

  Widget get preview => data.createPreview();
}

class ListBlockWidget extends StatefulWidget {
  final ListBlockData data;
  const ListBlockWidget({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<ListBlockWidget> createState() => _ListBlockWidgetState();
}

class _ListBlockWidgetState extends State<ListBlockWidget> {
  void applyTextChange(int index, String value) {
    final itemInserted = widget.data.applyTextChange(index, value);
    if (mounted && itemInserted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.data.items.length + 1,
      itemBuilder: (_, index) => ListItemWidget(
        index: index,
        prefix: widget.data.getItemPrefix(index),
        applyTextChange: applyTextChange,
      ),
    );
  }
}

typedef IndexedTextChanged = void Function(int, String);

class ListItemWidget extends StatefulWidget {
  final int index;
  final Widget prefix;
  final IndexedTextChanged applyTextChange;
  const ListItemWidget({
    Key? key,
    required this.index,
    required this.prefix,
    required this.applyTextChange,
  }) : super(key: key);

  @override
  State<ListItemWidget> createState() => _ListItemWidgetState();
}

class _ListItemWidgetState extends State<ListItemWidget> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focus.requestFocus();
  }

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        widget.prefix,
        Expanded(
          child: TextField(
            // enabled: true,
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: const BorderSide(
                  color: Colors.white38,
                  width: 1,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide.none,
              ),
            ),
            controller: controller,
            focusNode: focus,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              widget.applyTextChange(widget.index, value);
            },
            maxLines: null,
          ),
        ),
      ],
    );
  }
}
