import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/flow/circular_layout_mixin.dart';

enum FlowDirection {
  left,
  right,
  up,
  down,
}

/// [child] : the widget will be painted
/// [onPressed] if not null, use [TextButton] to wrap [child]
class FlowEntry {
  final Widget child;
  final VoidCallback? onPressed;

  FlowEntry({required this.child, required this.onPressed});
}

/// [entries] all [FlowEntry] will be painted by [FlowButtonDelegate]
/// [duration] the duration when playing the animation during painting [entries]
/// [direction] is used to determine which [FlowDirection] to paint [entries]
/// [curve] the [Curve] of [FlowButtonDelegate] animation
/// [alignment] how align the [entries] to the parent of [FlowButtons]
/// [mainEntry] in [FlowButtonDelegate], [mainEntry] is always zero. if [mainEntry] is not equal to zero,
/// it will be reorder [entries] to translate [mainEntry] to zero
class FlowButtons extends StatefulWidget {
  final List<FlowEntry> entries;
  final Duration? duration;
  final FlowDirection direction;
  final Curve curve;
  final Alignment alignment;
  final int mainEntry;
  const FlowButtons({
    Key? key,
    required this.entries,
    this.duration,
    this.direction = FlowDirection.left,
    this.curve = Curves.bounceInOut,
    this.alignment = Alignment.center,
    this.mainEntry = 0,
  }) : super(key: key);

  @override
  State<FlowButtons> createState() => FlowButtonsState();
}

class FlowButtonsState extends State<FlowButtons>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 300),
    );

    if (widget.mainEntry != 0) {
      final entry = widget.entries.removeAt(widget.mainEntry);
      widget.entries.insert(0, entry);
    }
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
    return Flow(
      // delegate: FlowButtonDelegate(
      //   animation: CurvedAnimation(
      //     parent: controller,
      //     curve: widget.curve,
      //   ),
      //   mainEntry: widget.mainEntry,
      //   alignment: widget.alignment,
      //   direction: widget.direction,
      // ),
      delegate: FlowCircularDelegate(
        animation: CurvedAnimation(
          parent: controller,
          curve: widget.curve,
        ),
        alignment: widget.alignment,
        startAngle: pi / 2,
      ),
      children: List.generate(
        widget.entries.length,
        (index) {
          final entry = widget.entries[index];

          return TextButton(
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

class FlowButtonDelegate extends FlowDelegate {
  final int mainEntry;
  final FlowDirection direction;
  final Animation<double> animation;
  final Alignment alignment;
  FlowButtonDelegate({
    required this.mainEntry,
    required this.animation,
    required this.alignment,
    this.direction = FlowDirection.down,
  }) : super(repaint: animation);

  @override
  bool shouldRepaint(FlowButtonDelegate oldDelegate) {
    return animation != oldDelegate.animation ||
        mainEntry != oldDelegate.mainEntry;
  }

  /// must ensure the constraint of children is loosen;
  /// in [Flex]-like widgets, it may pass its uncompleted loosen constraints, like (0<=w<=100, h=100)
  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final mainEntrySize = context.getChildSize(mainEntry) ?? Size.zero;

    final anchorOffset = getAnchorOffset(context.size, mainEntrySize);

    if (animation.value == 0) {
      final childSize = context.getChildSize(mainEntry)!;

      final offset = calculateOffset(anchorOffset, childSize, mainEntry);

      context.paintChild(
        mainEntry,
        transform: _createTransform(offset.dx, offset.dy, anchorOffset),
      );
      return;
    }

    for (int i = 0; i < context.childCount; i++) {
      final childSize = context.getChildSize(i)!;

      final childOffset = calculateOffset(anchorOffset, childSize, i);

      context.paintChild(
        i,
        transform:
            _createTransform(childOffset.dx, childOffset.dy, anchorOffset),
      );
    }
  }

  Offset getAnchorOffset(Size parentSize, Size entrySize) {
    final Offset offset = Offset(-entrySize.width / 2, 0);
    return alignment.alongSize(parentSize) + offset;
  }

  /// calculate the offset relative to the [anchor] when changing during animation
  Offset calculateOffset(Offset anchor, Size childSize, int index) {
    double? dx;
    double? dy;

    switch (direction) {
      case FlowDirection.left:
      case FlowDirection.right:
        dx = childSize.width * index * animation.value;
        break;
      case FlowDirection.down:
      case FlowDirection.up:
        dy = childSize.height * index * animation.value;
        break;
    }
    return Offset(dx ?? 0, dy ?? 0);
  }

  /// translate the child to the specific position based on [anchor] and itself offset calculated during animation by [calculateOffset]
  Matrix4 _createTransform(double dx, double dy, Offset anchor) {
    double? verticalOffset;
    double? horizontalOffset;

    switch (direction) {
      case FlowDirection.up:
        verticalOffset = anchor.dy - dy;
        break;
      case FlowDirection.down:
        verticalOffset = anchor.dy + dy;
        break;
      case FlowDirection.left:
        horizontalOffset = anchor.dx - dx;
        break;
      case FlowDirection.right:
        horizontalOffset = anchor.dx + dx;
        break;
    }

    return Matrix4.translationValues(
      horizontalOffset ?? anchor.dx,
      verticalOffset ?? anchor.dy,
      0,
    );
  }
}

class FlowCircularDelegate extends FlowDelegate with CircularLayoutMixin {
  @override
  final Animation<double> animation;
  final double angle;
  @override
  final double? startAngle;
  final double? radius;
  @override
  final Alignment alignment;

  FlowCircularDelegate({
    required this.animation,
    this.angle = 180,
    this.radius = 100,
    this.startAngle,
    this.alignment = Alignment.center,
  }) : super(repaint: animation);

  @override
  bool shouldRepaint(FlowCircularDelegate oldDelegate) {
    return animation != oldDelegate.animation || angle != oldDelegate.angle;
  }

  /// must ensure the constraint of children is loosen;
  /// in [Flex]-like widgets, it may pass its uncompleted loosen constraints, like (0<=w<=100, h=100)
  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final anchor = getAnchorOffset(context.size, Size.zero);

    final double perRad = angle / 180 * pi / (context.childCount - 1);
    final effectiveRadius = radius ?? context.size.shortestSide / 2;

    if (animation.value == 0) {
      context.paintChild(
        0,
        transform: createTransform(Offset.zero, anchor),
      );
      return;
    }

    for (int i = 0; i < context.childCount; i++) {
      final childSize = context.getChildSize(i) ?? Size.zero;

      final childOffset =
          calculateOffset(childSize, effectiveRadius, i, perRad);

      context.paintChild(
        i,
        transform: createTransform(childOffset, anchor),
      );
    }
  }
}
