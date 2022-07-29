import 'package:flutter/material.dart';

class AnimatedTransform extends ImplicitlyAnimatedWidget {
  final Matrix4? transform;
  final Offset? origin;
  final Widget? child;
  const AnimatedTransform({
    Key? key,
    this.transform,
    this.child,
    this.origin,
    Curve curve = Curves.easeIn,
    Duration duration = const Duration(milliseconds: 200),
  }) : super(
          key: key,
          curve: curve,
          duration: duration,
        );

  @override
  AnimatedWidgetBaseState<AnimatedTransform> createState() =>
      AnimatedTransformState();
}

class AnimatedTransformState
    extends AnimatedWidgetBaseState<AnimatedTransform> {
  Matrix4Tween? _transform;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _transform = visitor(_transform, widget.transform,
            (dynamic value) => Matrix4Tween(begin: value as Matrix4))
        as Matrix4Tween?;
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = this.animation;

    if (_transform == null) {
      return widget.child!;
    } else {
      return Transform(
        transform: _transform!.evaluate(animation),
        origin: widget.origin,
        child: widget.child,
      );
    }
  }
}
