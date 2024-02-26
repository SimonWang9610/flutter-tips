import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

final class ActionController extends TickerProvider with ChangeNotifier {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
  );

  ActionController({
    int? index,
  }) : _index = index {
    _animationController.addListener(() {
      notifyListeners();
    });
  }

  int? _index;
  int? get index => _index;
  double? get progress => _animationController.value;

  Future<void> expand(
    int index, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 150),
  }) async {
    if (_index != index) {
      _index = index;
      _animationController.reset();
      // await _animationController.animateTo(1, curve: curve, duration: duration);
      await _animationController.fling(velocity: 1);
    }
  }

  Future<void> collapse(
    int index, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 150),
  }) async {
    if (_index == index) {
      // await _animationController.animateBack(
      //   0,
      //   curve: curve,
      //   duration: duration,
      // );
      await _animationController.fling(velocity: -1);

      _index = null;
    }
  }

  Future<void> toggle(
    int index, {
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 150),
  }) async {
    if (_index == index) {
      await collapse(index, curve: curve, duration: duration);
    } else {
      await expand(index, curve: curve, duration: duration);
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
