import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'models.dart';

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
      _ratio = _animationController.value;
      notifyListeners();
    });

    _animationValue = _ratio;
  }

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  Axis _axis;
  Axis get axis => _axis;
  set axis(Axis axis) {
    if (_axis != axis) {
      _axis = axis;
      notifyListeners();
    }
  }

  Size? _size;
  Size? get size => _size;
  set size(Size? size) {
    if (_size != size) {
      _size = size;
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
    assert(size != null);
    final newRatio = switch (axis) {
      Axis.horizontal => (value / size!.width).clamp(-1, 1).toDouble(),
      Axis.vertical => (value / size!.height).clamp(-1, 1).toDouble(),
    };

    if (newRatio != _ratio) {
      // _ratio = newRatio;
      // // value = _ratio;
      _animationValue = newRatio;
    }
  }

  Future<double> toggle({
    Curve curve = Curves.easeOutCubic,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final future = switch (_ratio) {
      < -0.3 => _animationController.animateTo(
          -1,
          curve: curve,
          duration: duration,
        ),
      > -0.3 && < 0.3 => _animationController.animateTo(
          0,
          curve: curve,
          duration: duration,
        ),
      > 0.3 => _animationController.animateTo(
          1,
          curve: curve,
          duration: duration,
        ),
      _ => Future.value(),
    };

    return future.then((_) {
      return switch (axis) {
        Axis.horizontal => _ratio * size!.width,
        Axis.vertical => _ratio * size!.height,
      };
    });
  }

  /// the ratio of the distance that the main child has moved relative its size
  double _ratio = 0;
  double get ratio => _ratio;
  double get absoluteRatio => _ratio.abs();

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

  @override
  void dispose() {
    _ratio = 0;
    _animationController.dispose();
    super.dispose();
  }
}

mixin SlideControllerAnimationMixin on TickerProvider {
  static const double _lowerBound = -1;
  static const double _upperBound = 1;

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    lowerBound: _lowerBound,
    upperBound: _upperBound,
  );

  set _duration(Duration duration) {
    _animationController.duration = duration;
  }

  set _reverseDuration(Duration duration) {
    _animationController.reverseDuration = duration;
  }

  set _animationValue(double value) {
    _animationController.value = value;
  }
}
