import 'package:flutter/material.dart';
import 'delegates/button_flow_delegate.dart';
import 'models.dart';

typedef FlowButtonDelegateBuilder<T extends ButtonFlowDelegate> = T Function(
    Animation<double>);

class FlowButtonBar extends StatefulWidget {
  final Duration duration;
  final Curve curve;
  final Alignment alignment;
  final List<FlowEntry> entries;
  final Clip clipBehavior;
  final FlowButtonDelegateBuilder delegateBuilder;
  const FlowButtonBar({
    Key? key,
    required this.entries,
    required this.delegateBuilder,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.bounceInOut,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  @override
  State<FlowButtonBar> createState() => _FlowButtonBarState();
}

class _FlowButtonBarState extends State<FlowButtonBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  late Animation<double> _animation;
  late FlowDelegate _delegate;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _createAnimation();
    _delegate = widget.delegateBuilder(_animation);
  }

  @override
  void didUpdateWidget(covariant FlowButtonBar oldWidget) {
    print("update flow button bar");
    super.didUpdateWidget(oldWidget);

    _createAnimation(shouldReset: widget.curve != oldWidget.curve);

    if (widget.curve != oldWidget.curve ||
        widget.delegateBuilder != oldWidget.delegateBuilder) {
      _delegate = widget.delegateBuilder(_animation);
    }
  }

  void _createAnimation({bool? shouldReset}) {
    if (shouldReset == null || shouldReset) {
      _animation = CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void toggle() {
    if (controller.status == AnimationStatus.completed) {
      controller.reverse();
    } else {
      controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Flow(
      clipBehavior: widget.clipBehavior,
      delegate: _delegate,
      children: List.generate(
        widget.entries.length,
        (index) {
          final entry = widget.entries[index];
          return entry.builder(toggle);
        },
      ),
    );
  }
}
