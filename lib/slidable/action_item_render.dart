import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

class RenderActionItem extends RenderProxyBox with RenderProxyBoxMixin {
  RenderActionItem({
    required double ratio,
    RenderBox? child,
  })  : _ratio = ratio,
        super(child);

  double _ratio;
  double get ratio => _ratio;
  set ratio(double value) {
    if (_ratio != value) {
      _ratio = value;
      markNeedsLayout();
    }
  }
}

class ActionItemExpander extends TickerProvider with ChangeNotifier {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
  );

  ActionItemExpander({
    int? index,
  }) : _index = index {
    _animationController.addListener(() {
      notifyListeners();
    });
  }

  int? _index;
  int? get index => _index;
  double? get progress => _animationController.value;

  void expand(
    int index, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (_index != index) {
      _index = index;
      _animationController.duration = duration;
      _animationController.reset();
      _animationController.forward();
    }
  }

  bool hasExpandedAt(int index) => _index == index;

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  void reset() {
    _index = null;
    _animationController.reset();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
