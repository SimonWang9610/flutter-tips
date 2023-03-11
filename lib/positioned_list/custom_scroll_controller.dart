// import 'dart:async';

// import 'package:flutter/widgets.dart';
// import 'package:flutter_tips/positioned_list/observer/onstage_strategy.dart';

// import 'observer/scroll_observer.dart';
// import 'observer/scroll_extent.dart';
// import 'observer/scroll_mixin.dart';

// class CustomScrollController extends ScrollController with ScrollMixin {
//   final Map<Object, ScrollObserver> _observers;

//   CustomScrollController({
//     super.initialScrollOffset,
//     super.keepScrollOffset,
//     super.debugLabel,
//     Map<Object, ScrollObserver>? observers,
//   }) : _observers = observers ?? {};

//   @override
//   void dispose() {
//     super.dispose();

//     if (_animationRevealing != null && !_animationRevealing!.isCompleted) {
//       _animationRevealing?.complete();
//     }
//     _animationRevealing = null;

//     for (final observer in _observers.values) {
//       observer.clear();
//     }
//     _observers.clear();
//   }

//   ScrollObserver createOrObtainObserver(
//     String observerKey, {
//     bool forMultiChild = true,
//     int? itemCount,
//   }) {
//     if (_observers.containsKey(observerKey)) {
//       final observer = _observers[observerKey]!;
//       if (observer.itemCount != itemCount && itemCount != null) {
//         observer.itemCount = itemCount;
//       }

//       return observer;
//     } else {
//       final observer = forMultiChild
//           ? ScrollObserver.multi(label: observerKey, itemCount: itemCount)
//           : ScrollObserver.single(label: observerKey);

//       _observers[observerKey] = observer;
//       return observer;
//     }
//   }

//   void showInViewport(String observerKey) {
//     if (_observers.containsKey(observerKey)) {
//       _observers[observerKey]!.showInViewport(position);
//     }
//   }

//   void jumpToIndex(
//     int index, {
//     required String whichObserver,
//     bool keepAtTop = true,
//   }) {
//     assert(_observers.containsKey(whichObserver),
//         "Cannot jumpTo $index since no [ScrollObserver] is provided for $whichObserver.");
//     _scrollToUnrevealedIndex(whichObserver, index, keepAtTop: keepAtTop);
//   }

//   void _scrollToUnrevealedIndex(String whichObserver, int index,
//       {bool keepAtTop = true}) {
//     final observer = _observers[whichObserver]!;

//     index = observer.normalizeIndex(index);

//     if (!observer.visible) {
//       observer.showInViewport(position);
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _scrollToUnrevealedIndex(whichObserver, index, keepAtTop: keepAtTop);
//       });
//     } else {
//       final isOnstage = observer.isOnStage(
//         index,
//         scrollExtent: ScrollExtent.fromPosition(position),
//         strategy: PredicatorStrategy.inside,
//       );

//       if (!isOnstage) {
//         jumpWithoutCheck(observer, index);

//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _scrollToUnrevealedIndex(whichObserver, index, keepAtTop: keepAtTop);
//         });
//       } else if (isOnstage && keepAtTop) {
//         adjustScrollWithTolerance(observer, index);
//       }
//     }
//   }

//   Completer<void>? _animationRevealing;

//   /// if [animateToIndex] is invoked when [_animationRevealing] is not completed
//   /// we schedule revealing [index] after the previous revealing ends
//   /// if no [_animationRevealing] is active, we start animating instantly
//   /// By doing so, we might avoid conflicts between two continuous revealing animation
//   Future<void> animateToIndex(
//     int index, {
//     required String whichObserver,
//     bool keepAtTop = true,
//     required Duration duration,
//     required Curve curve,
//   }) async {
//     assert(_observers.containsKey(whichObserver),
//         "Cannot jumpTo $index since no [ScrollObserver] is provided for $whichObserver.");

//     if (_animationRevealing != null && !_animationRevealing!.isCompleted) {
//       _animationRevealing?.future.whenComplete(
//         () => animateToIndex(
//           index,
//           whichObserver: whichObserver,
//           duration: duration,
//           curve: curve,
//         ),
//       );
//     } else {
//       _animationRevealing = null;
//       _animationRevealing = Completer();
//       _revealingIndexWithAnimation(
//         whichObserver,
//         index,
//         duration: duration,
//         curve: curve,
//       );
//     }

//     return _animationRevealing!.future;
//   }

//   /// if [ScrollObserver.visible] is false, we should first try to reveal its viewport
//   /// once its sliver in the viewport is visible
//   /// we continue revealing for [index]
//   /// if [index] is not onstage before the current revealing
//   /// we should wait the current animated revealing ending, and then schedule the next revealing
//   ///
//   /// if we need to adjust the [index] at the leadingEdge/trailingEdge (corresponding to if list/grid is reversed)
//   /// we would wait the current revealing ending and then complete [_animationRevealing]
//   /// since we know [index] must be onstage at that time
//   FutureOr<void> _revealingIndexWithAnimation(
//     String whichObserver,
//     int index, {
//     required Duration duration,
//     required Curve curve,
//     bool keepAtTop = true,
//   }) async {
//     assert(_animationRevealing != null);

//     print("revealing for $index");

//     final observer = _observers[whichObserver]!;

//     index = observer.normalizeIndex(index);

//     if (!observer.visible) {
//       // todo: should enable animation when revealing the invisible viewport?
//       // todo: if enabling animation, should wait viewport revealing ending to schedule the next revealing?
//       observer.showInViewport(position, duration: duration, curve: curve);

//       Future.delayed(
//         duration,
//         () {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _revealingIndexWithAnimation(
//               whichObserver,
//               index,
//               keepAtTop: keepAtTop,
//               duration: duration,
//               curve: curve,
//             );
//           });
//         },
//       );
//     } else {
//       final isOnstage = observer.isOnStage(
//         index,
//         scrollExtent: ScrollExtent.fromPosition(position),
//         strategy: PredicatorStrategy.inside,
//       );

//       if (!isOnstage) {
//         await jumpWithoutCheck(
//           observer,
//           index,
//           duration: duration,
//           curve: curve,
//         );

//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _revealingIndexWithAnimation(
//             whichObserver,
//             index,
//             duration: duration,
//             curve: curve,
//             keepAtTop: keepAtTop,
//           );
//         });
//       } else if (isOnstage && keepAtTop) {
//         await adjustScrollWithTolerance(
//           observer,
//           index,
//           duration: duration,
//           curve: curve,
//         );

//         _animationRevealing?.complete();
//       } else {
//         _animationRevealing?.complete();
//       }
//     }
//   }
// }
