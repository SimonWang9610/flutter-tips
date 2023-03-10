import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tips/positioned_list/item_scroll_model.dart';

import 'scroll_observer.dart';

class MultiChildScrollObserver extends ScrollObserver {
  MultiChildScrollObserver({super.label});

  @override
  void onLayout(RenderSliver value) {
    assert(
        value is ContainerRenderObjectMixin<RenderBox,
            SliverMultiBoxAdaptorParentData>,
        "$runtimeType is designed for multi children slivers, but ${value.runtimeType} is not suitable for this scroll observer");
    super.onLayout(value);
  }

  // todo: should set _sliver = null after observing?
  @override
  void onFinishLayout(int firstIndex, int lastIndex) {
    super.onFinishLayout(firstIndex, lastIndex);

    assert(
        sliver is ContainerRenderObjectMixin<RenderBox,
            SliverMultiBoxAdaptorParentData>,
        "${sliver.runtimeType} does not contain multi box-based children");

    // print("[$label]: didFinishedLayout [$firstIndex, $lastIndex]");

    final bool shouldObserveModel = shouldObserve(firstIndex, lastIndex);

    if (shouldObserveModel) {
      _first = firstIndex;
      _last = lastIndex;

      RenderBox? child = (sliver as RenderSliverMultiBoxAdaptor).firstChild;

      double totalExtent = 0;
      int count = 0;

      while (child != null) {
        final currentParentData =
            child.parentData! as SliverMultiBoxAdaptorParentData;

        assert(_sizes.containsKey(currentParentData.index!),
            "The size of child should be observed before finishing layout");

        //! not using [RenderBox.size] directly to avoid assertions failed in debug mode
        final model = ItemScrollModel.multi(
            currentParentData, _sizes[currentParentData.index!]!);

        models[model.index] = model;

        totalExtent += model.mainAxisOffset;
        count++;

        child = currentParentData.nextSibling;
      }

      if (count == 0) {
        count = 1;
      }

      _estimatedAveragePageGap =
          (_estimatedAveragePageGap + totalExtent / count) / 2;
    }
  }

  final Map<int, Size> _sizes = {};

  @override
  void observeSize(ParentData parentData, Size size) {
    assert(parentData is SliverMultiBoxAdaptorParentData);
    _sizes[(parentData as SliverMultiBoxAdaptorParentData).index!] = size;
  }

  double _estimatedAveragePageGap = 0;

  @override
  double estimateScrollOffset(int target,
      {required double maxScrollExtent, required double minScrollExtent}) {
    assert(
      models.containsKey(_first) && models.containsKey(_last),
      "[ItemScrollModel] for index $_first and $_last should be observed "
      "during $runtimeType.onFinishLayout.",
    );

    double estimated = origin.offset;

    if (models.containsKey(target)) {
      estimated += getItemScrollModel(target)!.mainAxisOffset;
    } else {
      final currentIndexGap = _last - _first > 0 ? _last - _first : 1;

      if (target < _first) {
        estimated += getItemScrollModel(_first)!.mainAxisOffset +
            (target - _first) / currentIndexGap * _estimatedAveragePageGap;
      } else if (target > _last) {
        estimated += getItemScrollModel(_last)!.mainAxisOffset +
            (target - _last) / currentIndexGap * _estimatedAveragePageGap;
      } else {
        assert(
          false,
          "This line should never reach. Since $target is in [$_first, $_last], "
          "its [itemScrollModel] should be observed during $runtimeType.didFinishLayout",
        );
      }
    }

    final leadingEdge = max(origin.offset, minScrollExtent);

    return clampDouble(estimated, leadingEdge, maxScrollExtent);
  }

  @override
  ItemScrollModel? getItemScrollModel(int index) => models[index];

  int _first = 0;
  int _last = 0;

  @override
  bool shouldObserve(int first, int last) {
    return _first != first || _last != last;
  }
}
