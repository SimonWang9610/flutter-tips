import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/flow/delegates/circular_flow_delegate.dart';
import 'package:flutter_tips/flow/delegates/linear_flow_delegate.dart';

import '../components/outlined_text_button.dart';
import 'models.dart';

class FlowButtons extends StatefulWidget {
  final Duration duration;
  final Curve curve;
  final Alignment alignment;
  final List<FlowEntry> entries;
  final Clip clipBehavior;
  final FlowType type;
  final FlowTypeParams params;
  const FlowButtons({
    Key? key,
    required this.entries,
    required this.type,
    required this.params,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.bounceInOut,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  @override
  State<FlowButtons> createState() => _FlowButtonsState();
}

class _FlowButtonsState extends State<FlowButtons>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void activateButton() {
    if (controller.status == AnimationStatus.completed) {
      controller.reverse();
    } else {
      controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: widget.curve,
    );

    late FlowDelegate delegate;

    switch (widget.type) {
      case FlowType.linear:
        delegate = LinearFlowDelegate(
          animation: animation,
          params: widget.params as LinearFlowParams,
        );
        break;
      case FlowType.circular:
        delegate = CircularFlowDelegate(
          animation: animation,
          params: widget.params as CircularFlowParams,
        );
        break;
    }
    return Flow(
      clipBehavior: widget.clipBehavior,
      delegate: delegate,
      children: List.generate(
        widget.entries.length,
        (index) {
          final entry = widget.entries[index];

          return OutlinedTextButton(
            style: entry.style,
            onPressed: () {
              entry.onPressed?.call();
              activateButton();
            },
            child: entry.child,
          );
        },
      ),
    );
  }
}
