import 'package:flutter/material.dart';

enum ListBlockStyle {
  unordered('unordered'),
  ordered('ordered');

  final String style;

  const ListBlockStyle(this.style);
}

class ListBlockData {
  final String id;
  final String type;
  final ListBlockStyle style;
  final List<String> items;

  ListBlockData({
    required this.id,
    required this.type,
    required this.style,
    List<String>? initItems,
  }) : items = initItems ?? [];

  bool applyTextChange(int index, String value) {
    if (items.length > index) {
      items[index] = value;
      return false;
    } else {
      items.add(value);
      return true;
    }
  }

  Widget getItemPrefix(int index) {
    switch (style) {
      case ListBlockStyle.ordered:
        return Text(
          '${index + 1}.',
          style: const TextStyle(fontSize: 28),
        );
      case ListBlockStyle.unordered:
        return const Text(
          '•',
          style: TextStyle(fontSize: 28),
        );
    }
  }

  Widget buildItem(int index) {
    final Widget orderWidget = getItemPrefix(index);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        orderWidget,
        Text(items[index]),
      ],
    );
  }

  Widget createPreview() {
    return Center(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) => buildItem(index),
            ),
          )
        ],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'data': {
        'style': style.style,
        'items': items,
      }
    };
  }
}
