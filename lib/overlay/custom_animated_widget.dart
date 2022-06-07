import 'package:flutter/material.dart';

abstract class CustomAnimatedWidget<T> extends AnimatedWidget {
  final Widget child;
  final Animation<T> animation;
  const CustomAnimatedWidget({
    Key? key,
    required this.child,
    required this.animation,
  }) : super(key: key, listenable: animation);
}

class CustomAlign extends AnimatedWidget {
  final Widget child;
  final Animation<Alignment> animation;

  const CustomAlign({
    Key? key,
    required this.child,
    required this.animation,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: animation.value,
      child: child,
    );
  }
}
