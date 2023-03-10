import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'item_scroll_model.dart';

class ScrollObserver {
  final String? label;
  final Map<int, ItemScrollModel> models = {};

  ScrollObserver({this.label});

  void observe(SliverMultiBoxAdaptorParentData parentData, Size size) {
    final model = ItemScrollModel.multi(parentData, size);

    models[model.index] = model;
    // print("[ScrollObserver: $label]: ${models.length}, current: $model");
  }

  int _first = 0;
  int _last = 0;

  SliverConstraints? _constraints;
  SliverGeometry? _geometry;

  SliverGeometry? get geometry => _geometry;
  SliverConstraints get constraints => _constraints!;

  bool shouldObserve(int first, int last) {
    return _first != first || _last != last;
  }

  RenderSliver? _sliver;
  RenderSliver? get sliver => _sliver;

  void onLayout(RenderSliver? sliver) {
    if (_sliver != sliver) {
      _sliver = sliver;
      print("$label: onLayout");
    }
  }

  void onFinishLayout(int firstIndex, int lastIndex) {
    assert(_sliver != null);

    print("$label: ${_sliver?.geometry}");

    if (sliver is ContainerRenderObjectMixin<RenderBox,
        SliverMultiBoxAdaptorParentData>) {
      final multiBoxAdaptor = sliver as RenderSliverMultiBoxAdaptor;

      final firstIndex = multiBoxAdaptor.firstChild != null
          ? multiBoxAdaptor.indexOf(multiBoxAdaptor.firstChild!)
          : 0;
      final lastIndex = multiBoxAdaptor.lastChild != null
          ? multiBoxAdaptor.indexOf(multiBoxAdaptor.lastChild!)
          : 0;

      final bool shouldReportObserve = shouldObserve(firstIndex, lastIndex);

      if (shouldReportObserve) {
        _first = firstIndex;
        _last = lastIndex;

        RenderBox? child = multiBoxAdaptor.firstChild;

        while (child != null) {
          final currentParentData =
              child.parentData! as SliverMultiBoxAdaptorParentData;

          // observe(currentParentData, child.size);
          print(currentParentData);

          child = currentParentData.nextSibling;
        }
      }
    } else if (sliver is RenderObjectWithChildMixin<RenderBox>) {
      // todo: the render sliver has only single child
    }
  }

  void observeRange(
    int first,
    int last, {
    required SliverConstraints constraints,
    required SliverGeometry geometry,
  }) {
    if (_first != first || _last != last) {
      _first = first;
      _last = last;

      // print("first: $_first, last: $_last, length: ${models.length}");
    }

    if (_constraints != constraints || _geometry != geometry) {
      _constraints = constraints;
      _geometry = geometry;
      // print(" observerRange: ${_geometry != null} ");
    }
  }

  ItemScrollModel? getItemScrollModel(int index) => models[index];

  void clear() => models.clear();

  @override
  String toString() {
    return "ScrollObserver(label: $label, model count: ${models.length}, first: $_first, last: $_last, $_constraints, $_geometry)";
  }

  double estimateScrollOffset(int target,
      {required double maxScrollExtent, required double minScrollExtent}) {
    assert(models.containsKey(_first) && models.containsKey(_last),
        " $_first and $_last are not observed");

    if (models.containsKey(target)) {
      return models[target]!.mainAxisOffset;
    }

    final firstScroll = getItemScrollModel(_first)!;
    final lastScroll = getItemScrollModel(_last)!;

    final pageOffsetGap =
        lastScroll.mainAxisOffset - firstScroll.mainAxisOffset;
    final currentGap = _last - _first > 0 ? _last - _first : 1;

    double estimated = 0.0;

    if (target < _first) {
      estimated = firstScroll.mainAxisOffset +
          (target - _first) / currentGap * pageOffsetGap;
    } else if (target > _last) {
      estimated = lastScroll.mainAxisOffset +
          (target - _last) / currentGap * pageOffsetGap;
    } else {
      assert(models.containsKey(target));
      estimated = getItemScrollModel(target)!.mainAxisOffset;
    }

    return clampDouble(estimated, minScrollExtent, maxScrollExtent);
  }

  ItemScrollModel? getEdgeModel({bool leftEdge = true}) {
    if (models.isEmpty) return null;

    int edgeKey = models.keys.first;

    for (final key in models.keys) {
      if (leftEdge) {
        edgeKey = min(edgeKey, key);
      } else {
        edgeKey = max(edgeKey, key);
      }
    }
    return models[edgeKey]!;
  }
}
