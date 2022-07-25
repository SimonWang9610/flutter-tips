import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class PanGestureDetector extends StatelessWidget {
  final Widget? child;
  final GestureDragDownCallback? onPanDown;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;
  final HitTestBehavior behavior;
  final DragStartBehavior dragStartBehavior;
  final bool excludeFromSemantics;
  const PanGestureDetector({
    Key? key,
    this.child,
    this.onPanDown,
    this.onPanEnd,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanCancel,
    this.behavior = HitTestBehavior.translucent,
    this.dragStartBehavior = DragStartBehavior.down,
    this.excludeFromSemantics = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures = {};
    final DeviceGestureSettings? gestureSettings =
        MediaQuery.maybeOf(context)?.gestureSettings;

    if (onPanDown != null ||
        onPanStart != null ||
        onPanUpdate != null ||
        onPanEnd != null ||
        onPanCancel != null) {
      gestures[PanGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
        () => PanGestureRecognizer(debugOwner: this),
        (PanGestureRecognizer instance) {
          instance
            ..onDown = onPanDown
            ..onStart = onPanStart
            ..onUpdate = onPanUpdate
            ..onEnd = onPanEnd
            ..onCancel = onPanCancel
            ..dragStartBehavior = dragStartBehavior
            ..gestureSettings = gestureSettings;
        },
      );
    }

    return RawGestureDetector(
      gestures: gestures,
      behavior: behavior,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }
}
