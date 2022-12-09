import 'package:flutter/material.dart';

enum FlowDirection {
  left,
  right,
  up,
  down,
}

enum FlowType {
  linear,
  circular,
}

typedef FlowEntryBuilder = Widget Function(VoidCallback toggleFlowButtonBar);

class FlowEntry {
  final FlowEntryBuilder builder;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  FlowEntry({
    required this.builder,
    this.onPressed,
    this.style,
  });
}
