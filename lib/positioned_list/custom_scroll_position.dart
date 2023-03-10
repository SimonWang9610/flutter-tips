import 'package:flutter/material.dart';

class CustomScrollPosition extends ScrollPositionWithSingleContext {
  final ValueNotifier<ScrollExtent> _scrollExtent;

  CustomScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  }) : _scrollExtent = ValueNotifier(const ScrollExtent());

  ValueNotifier<ScrollExtent> get scrollExtent => _scrollExtent;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    final applied =
        super.applyContentDimensions(minScrollExtent, maxScrollExtent);

    _scrollExtent.value = ScrollExtent(
        min: minScrollExtent, max: maxScrollExtent, current: pixels);

    return applied;
  }

  @override
  void dispose() {
    _scrollExtent.dispose();
    super.dispose();
  }
}

class ScrollExtent {
  final double min;
  final double max;
  final double current;

  const ScrollExtent({this.min = 0.0, this.max = 0.0, this.current = 0.0});

  @override
  bool operator ==(covariant ScrollExtent other) {
    return identical(this, other) || (hashCode == other.hashCode);
  }

  @override
  int get hashCode => min.hashCode ^ max.hashCode ^ current.hashCode;

  @override
  String toString() =>
      ("ScrollExtent(min: $min, max: $max, current: $current)");
}
