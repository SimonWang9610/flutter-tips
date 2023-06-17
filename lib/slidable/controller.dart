import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'models.dart';

const double _lowerBound = -1;
const double _upperBound = 1;
const double _middleBound = 0;

class SlideController extends TickerProvider
    with ChangeNotifier, SlideControllerAnimationMixin {
  SlideController({
    Axis axis = Axis.horizontal,
    double visibleThreshold = 0.5,
    Duration? duration,
    Duration? reverseDuration,
  })  : _axis = axis,
        _visibleThreshold = visibleThreshold {
    _animationController.addListener(() {
      notifyListeners();
    });
  }

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Axis _axis;
  Axis get axis => _axis;
  set axis(Axis axis) {
    if (_axis != axis) {
      _axis = axis;
      notifyListeners();
    }
  }

  LayoutSize? _layoutSize;
  LayoutSize? get layoutSize => _layoutSize;
  set layoutSize(LayoutSize? layoutSize) {
    if (_layoutSize != layoutSize) {
      _layoutSize = layoutSize;
    }
  }

  double _visibleThreshold;
  double get visibleThreshold => _visibleThreshold;
  set visibleThreshold(double visibleThreshold) {
    if (_visibleThreshold != visibleThreshold) {
      _visibleThreshold = visibleThreshold;
      notifyListeners();
    }
  }

  void slideTo(double value) {
    assert(layoutSize != null);
    final newRatio = layoutSize!
        .getRatio(axis, value)
        ?.clamp(_lowerBound, _upperBound)
        .toDouble();

    if (newRatio != null && newRatio != ratio) {
      _animationValue = newRatio;
    }
  }

  /// animate to the nearest target determined by [isForward] and the current [SlideDirection]
  /// if [isForward] is true, it will animate to the next target
  /// if [isForward] is false, it will always restore to the [_middleBound], hiding all actions

  Future<double?> toggle({
    required bool isForward,
    Curve curve = Curves.easeInOut,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final target = layoutSize!.getToggleTarget(direction, ratio, isForward);

    if (ratio != target) {
      return _animationController
          .animateTo(target, curve: curve, duration: duration)
          .then((_) => layoutSize!.getDragExtent(axis, ratio));
    }
    return Future.value();
  }

  /// represents the current sliding ratio relative to the size of the [SlidePanel]
  /// if [ratio] > 0  indicates we are sliding to see the pre actions
  /// if [ratio] < 0  indicates we are sliding to see the post actions
  /// if [ratio] == 0 indicates we are not sliding, all actions are hidden, only the main child is visible
  double get ratio => _animationController.value;
  double get absoluteRatio => ratio.abs();

  SlideDirection get direction {
    if (ratio == 0) {
      return SlideDirection.idle;
    }

    if (ratio > 0) {
      return switch (axis) {
        Axis.horizontal => SlideDirection.leftToRight,
        Axis.vertical => SlideDirection.topToBottom,
      };
    } else {
      return switch (axis) {
        Axis.horizontal => SlideDirection.rightToLeft,
        Axis.vertical => SlideDirection.bottomToTop,
      };
    }
  }
}

mixin SlideControllerAnimationMixin on TickerProvider {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    lowerBound: _lowerBound,
    upperBound: _upperBound,
  )..value = _middleBound;

  set _animationValue(double value) {
    _animationController.value = value;
  }
}
