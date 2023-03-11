import 'package:flutter/material.dart';

import 'scroll_extent.dart';

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

  /// when [RenderViewportBase] invoke this method on [ViewportOffset]
  /// it may not report the latest min and max scroll extent instantly
  /// since the min/max scroll extent would be corrected after scrolling
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
