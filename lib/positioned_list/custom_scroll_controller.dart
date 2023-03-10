import 'package:flutter/widgets.dart';
import 'package:flutter_tips/positioned_list/observer/onstage_strategy.dart';

import 'custom_scroll_position.dart';

import 'observer/scroll_observer.dart';

class CustomScrollController extends ScrollController {
  final Map<Object, ScrollObserver> _observers;

  CustomScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    Map<Object, ScrollObserver>? observers,
  }) : _observers = observers ?? {};

  @override
  CustomScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return CustomScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }

  @override
  CustomScrollPosition get position => super.position as CustomScrollPosition;

  ValueNotifier<ScrollExtent> get scrollExtent => position.scrollExtent;

  ScrollObserver createOrObtainObserver(String observerKey,
      {bool forMultiChild = true}) {
    if (_observers.containsKey(observerKey)) {
      return _observers[observerKey]!;
    } else {
      final observer = forMultiChild
          ? ScrollObserver.multi(label: observerKey)
          : ScrollObserver.single(label: observerKey);

      _observers[observerKey] = observer;
      return observer;
    }
  }

  void showInViewport(String observerKey) {
    if (_observers.containsKey(observerKey)) {
      _observers[observerKey]!.showInViewport(position);
    }
  }

  void jumpToIndex(
    int index, {
    required String whichObserver,
    bool keepAtTop = true,
  }) {
    assert(_observers.containsKey(whichObserver),
        "Cannot jumpTo $index since no [ScrollObserver] is provided for $whichObserver.");

    _scrollToUnrevealedIndex(whichObserver, index, keepAtTop: keepAtTop);
  }

  bool _indexRevealing = false;

  void _scrollToUnrevealedIndex(String whichObserver, int index,
      {bool keepAtTop = true}) {
    final observer = _observers[whichObserver]!;

    if (!observer.visible) {
      _indexRevealing = true;
      observer.showInViewport(position);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToUnrevealedIndex(whichObserver, index, keepAtTop: keepAtTop);
      });
    } else {
      final isOnstage = observer.isOnStage(
        index,
        scrollExtent: scrollExtent.value,
        strategy: PredicatorStrategy.inside,
      );

      if (!isOnstage) {
        _indexRevealing = true;
        _jumpWithoutCheck(observer, index);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToUnrevealedIndex(whichObserver, index, keepAtTop: keepAtTop);
        });
      } else if (isOnstage && keepAtTop) {
        final estimated = _estimateJumpingOffset(observer, index);

        if (estimated != null) {
          jumpTo(estimated);
        }
        _indexRevealing = false;
      } else {
        _indexRevealing = false;
      }
    }
  }

  void _jumpWithoutCheck(ScrollObserver observer, int index) {
    final targetOffset = observer.estimateScrollOffset(
      index,
      minScrollExtent: position.minScrollExtent,
      maxScrollExtent: position.maxScrollExtent,
    );
    jumpTo(targetOffset);
  }

  double? _estimateJumpingOffset(ScrollObserver observer, int index) {
    final estimated = observer.estimateScrollOffset(
      index,
      minScrollExtent: position.minScrollExtent,
      maxScrollExtent: position.maxScrollExtent,
    );
    final pixelDiff = estimated - position.pixels;

    final shouldContinue = pixelDiff > _kPixelDiffTolerance &&
        position.maxScrollExtent > position.pixels;

    return shouldContinue ? estimated : null;
  }
}

const double _kPixelDiffTolerance = 5;
