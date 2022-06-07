import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'custom_animated_widget.dart';

class CustomAnimatedOverlay extends AnimatedOverlay {
  CustomAnimatedOverlay(Duration duration) : super(duration);

  OverlayEntry? _entry;

  Alignment align = Alignment.centerRight;

  Animation<Alignment>? alignAnimation;

  OverlayEntry createAlignOverlay({Widget? child}) {
    return OverlayEntry(
      builder: (_) {
        return CustomAlign(
          animation: alignAnimation ?? AlwaysStoppedAnimation(align),
          child: child ??
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.red,
                ),
                child: const Text('Align Overlay'),
              ),
        );
      },
    );
  }

  void insert(BuildContext context, {Widget? child}) {
    _entry = createAlignOverlay(child: child);
    Overlay.of(context)?.insert(_entry!);
  }

  void alignChildTo(Offset globalPosition, Size size) {
    double dx = (globalPosition.dx - size.width) / size.width;
    double dy = (globalPosition.dy - size.height) / size.height;

    dx = dx.abs() < 1 ? dx : dx / dx.abs();
    dy = dy.abs() < 1 ? dy : dy / dy.abs();

    final newAlign = Alignment(dx, dy);

    if (align == newAlign) return;

    alignAnimation = createAnimation(begin: align, end: newAlign);

    align = newAlign;

    controller.forward();
    _entry?.markNeedsBuild();
  }

  void alignToScreenEdge() {
    alignAnimation =
        createAnimation<Alignment>(begin: align, end: Alignment.centerRight);

    align = Alignment.centerRight;

    controller.forward();
    _entry?.markNeedsBuild();
  }
}

abstract class AnimatedOverlay extends TickerProvider {
  @override
  Ticker createTicker(onTick) => Ticker(onTick);

  late final AnimationController controller;

  AnimatedOverlay(Duration duration) : super() {
    controller = AnimationController(
      vsync: this,
      duration: duration,
    );
  }

  Animation<T> createAnimation<T>({
    required T begin,
    required T end,
    Curve curve = Curves.easeInOutCubic,
  }) {
    controller.reset();
    if (begin == end) {
      return AlwaysStoppedAnimation<T>(end);
    } else {
      return Tween<T>(begin: begin, end: end).animate(
        CurvedAnimation(
          parent: controller,
          curve: curve,
        ),
      );
    }
  }
}
