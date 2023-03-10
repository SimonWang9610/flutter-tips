import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tips/positioned_list/custom_scroll_position.dart';
import 'package:flutter_tips/positioned_list/item_scroll_model.dart';
import 'package:flutter_tips/positioned_list/sliver_util.dart';

import 'multi_child_observer.dart';
import 'single_child_observer.dart';
import 'onstage_strategy.dart';

// todo: handle memory pressure when there are too much models
abstract class ScrollObserver {
  final String? label;
  final Map<int, ItemScrollModel> models = {};

  ScrollObserver({this.label});

  factory ScrollObserver.multi({String? label}) =>
      MultiChildScrollObserver(label: label);

  factory ScrollObserver.single({String? label}) =>
      SingleChildScrollObserver(label: label);

  RenderSliver? _sliver;
  RenderSliver? get sliver => _sliver;

  @mustCallSuper
  void onLayout(RenderSliver value) {
    if (_sliver != value) {
      _sliver = value;
      _shouldUpdateOffset = true;
    }
  }

  @mustCallSuper
  void onFinishLayout(int firstIndex, int lastIndex) {
    assert(
      sliver != null,
      "[RenderSliver] should be given in [onLayout]. Please calling $runtimeType.onLayout "
      "to specify a [RenderSliver] for this observer before calling this method.",
    );
    _updateSliverOffset();
  }

  bool _shouldUpdateOffset = false;
  bool _scheduledOffsetUpdate = false;

  bool get scheduledOffsetUpdate => _scheduledOffsetUpdate;

  RevealedOffset? _origin;
  RevealedOffset get origin {
    assert(_origin != null,
        "This getter should be accessed after $runtimeType.didFinishLayout");
    return _origin!;
  }

  void _updateSliverOffset() {
    assert(sliver != null);

    if (_shouldUpdateOffset) {
      try {
        // print("[$label]: ${sliver!.constraints}");
        // print("[$label]: ${sliver!.geometry}");

        final viewport = SliverUtil.findViewport(sliver!);

        _origin = viewport.getOffsetToReveal(sliver!, 0.0);

        _shouldUpdateOffset = false;
        _scheduledOffsetUpdate = false;
      } catch (e) {
        ///! if the sliver is the descendant of another sliver, its ancestor SliverGeometry mat not be ready
        ///! when its geometry is ready;
        ///! consequently, addPostFrameCallback to jump to the nested sliver may not work

        if (!_scheduledOffsetUpdate) {
          scheduleMicrotask(() {
            _scheduledOffsetUpdate = true;
            _updateSliverOffset();
          });
        }
      }
    }
  }

  void showInViewport(ViewportOffset offset,
      {Duration duration = Duration.zero,
      Curve curve = Curves.ease,
      int maxTraceCount = 5}) {
    if (_sliver == null) return;

    final viewport =
        SliverUtil.findViewport(_sliver!, maxTraceCount: maxTraceCount);

    RenderViewportBase.showInViewport(
      descendant: _sliver,
      viewport: viewport,
      offset: offset,
      duration: duration,
      curve: curve,
    );
  }

  bool isOnStage(
    int index, {
    required ScrollExtent scrollExtent,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
  }) {
    final itemScrollModel = getItemScrollModel(index);

    if (itemScrollModel == null || !visible) return false;

    final sliverConstraints = sliver!.constraints;
    final leadingOffset = origin.offset + itemScrollModel.mainAxisOffset;

    final double trailingOffset;

    switch (sliverConstraints.axis) {
      case Axis.vertical:
        trailingOffset = leadingOffset + itemScrollModel.size.height;
        break;
      case Axis.horizontal:
        trailingOffset = leadingOffset + itemScrollModel.size.width;
        break;
    }

    final trailingEdge =
        scrollExtent.current + sliverConstraints.viewportMainAxisExtent;

    return OnstagePredicator.predict(
      leadingOffset,
      trailingOffset,
      leadingEdge: scrollExtent.current,
      trailingEdge: trailingEdge,
      maxScrollExtent: scrollExtent.max,
    );
  }

  bool get visible =>
      sliver != null && sliver!.geometry != null && sliver!.geometry!.visible;

  void observeSize(ParentData parentData, Size size) {}

  double estimateScrollOffset(
    int target, {
    required double maxScrollExtent,
    required double minScrollExtent,
  });

  ItemScrollModel? getItemScrollModel(int index);

  bool shouldObserve(int first, int last) => true;

  void clear() {
    models.clear();
  }
}
