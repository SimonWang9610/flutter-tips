import 'package:flutter/material.dart';

import 'models.dart';

class CircularFlowButtons extends StatefulWidget {
  final List<FlowEntry> entries;
  final Duration? duration;
  final Curve curve;
  final Alignment alignment;
  final double startAngle;
  final double angle;
  final double radius;
  const CircularFlowButtons({
    Key? key,
    required this.entries,
    required this.radius,
    required this.angle,
    this.startAngle = 0,
    this.duration = const Duration(microseconds: 300),
    this.curve = Curves.bounceIn,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  State<CircularFlowButtons> createState() => _CircularFlowButtonsState();
}

class _CircularFlowButtonsState extends State<CircularFlowButtons>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
