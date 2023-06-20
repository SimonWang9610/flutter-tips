import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tips/slidable/action_item_expander.dart';
import 'models.dart';

const double _lowerBound = -1;
const double _upperBound = 1;
const double _middleBound = 0;

class SlideController extends _SlideAnimator {
  SlideController() {
    _animationController.addListener(() {
      notifyListeners();
    });
  }

  LayoutSize? _layoutSize;
  LayoutSize? get layoutSize => _layoutSize;

  @protected
  set layoutSize(LayoutSize? layoutSize) {
    if (_layoutSize != layoutSize) {
      _layoutSize = layoutSize;
    }
  }

  /// [value] is the dragging extent during sliding
  /// a positive value means the panel is sliding to show the pre actions
  /// a negative value means the panel is sliding to show the post actions
  @protected
  void slideTo(double value) {
    assert(layoutSize != null);
    final newRatio =
        layoutSize!.getRatio(value)?.clamp(_lowerBound, _upperBound).toDouble();

    if (newRatio != null && newRatio != ratio) {
      _animationValue = newRatio;
    }
  }

  /// animate to the nearest target determined by [isForward] and the current [SlideDirection]
  /// if [isForward] is true, it will animate to the next target
  /// if [isForward] is false, it will always restore to the [_middleBound], hiding all actions
  Future<double?> toggle({
    required bool isForward,
    Curve curve = Curves.bounceInOut,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    final target = layoutSize!.getToggleTarget(direction, ratio, isForward);

    if (ratio != target) {
      await _animationController.animateTo(
        target,
        curve: curve,
        duration: duration,
      );
    }
    return layoutSize!.getDragExtent(ratio);
  }

  // Simulation _simulate(double target, double velocity) {
  //   final springDesc =
  //       SpringDescription.withDampingRatio(mass: 1.0, stiffness: 500);

  //   return ScrollSpringSimulation(springDesc, ratio, target, velocity);
  // }

  Future<void> dismiss({
    Curve? curve,
    Duration? duration,
  }) async {
    final springDesc =
        SpringDescription.withDampingRatio(mass: 1.0, stiffness: 500);

    final simulation =
        ScrollSpringSimulation(springDesc, ratio, _middleBound, -1);

    await _animationController.animateWith(simulation);

    // if (duration != null) {
    //   return _animationController.animateTo(
    //     _middleBound,
    //     curve: curve ?? Curves.easeInOut,
    //     duration: duration,
    //   );
    // } else {
    //   return _animationController.fling(
    //     velocity: 1,
    //   );
    // }
  }

  SlideDirection get direction {
    assert(layoutSize != null);

    if (ratio == 0) {
      return SlideDirection.idle;
    }

    if (ratio > 0) {
      return switch (layoutSize!.axis) {
        Axis.horizontal => SlideDirection.leftToRight,
        Axis.vertical => SlideDirection.topToBottom,
      };
    } else {
      return switch (layoutSize!.axis) {
        Axis.horizontal => SlideDirection.rightToLeft,
        Axis.vertical => SlideDirection.bottomToTop,
      };
    }
  }
}

class _SlideAnimator extends TickerProvider with ChangeNotifier {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    lowerBound: _lowerBound,
    upperBound: _upperBound,
  )..value = _middleBound;

  set _animationValue(double value) {
    _animationController.value = value;
  }

  Animation<double> get animationValue => _animationController;

  /// represents the current sliding ratio relative to the size of the [SlidePanel]
  /// if [ratio] > 0  indicates we are sliding to see the pre actions
  /// if [ratio] < 0  indicates we are sliding to see the post actions
  /// if [ratio] == 0 indicates we are not sliding, all actions are hidden, only the main child is visible
  double get ratio => _animationController.value;
  double get absoluteRatio => ratio.abs();

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
