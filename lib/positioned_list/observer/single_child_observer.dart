import 'package:flutter/rendering.dart';
import 'package:flutter_tips/positioned_list/item_scroll_model.dart';

import 'scroll_observer.dart';

class SingleChildScrollObserver extends ScrollObserver {
  SingleChildScrollObserver({super.label});

  @override
  void onLayout(RenderSliver value) {
    assert(value is RenderObjectWithChildMixin<RenderBox>,
        "$runtimeType is designed for single child sliver, but ${value.runtimeType} is not suitable for this scroll observer");
    super.onLayout(value);
  }

  @override
  void onFinishLayout(int firstIndex, int lastIndex) {
    super.onFinishLayout(firstIndex, lastIndex);

    assert(sliver is RenderObjectWithChildMixin<RenderBox>,
        "${sliver.runtimeType} does not contain single box-based child");

    if (shouldObserve(firstIndex, lastIndex)) {
      assert(_size != null,
          "The size of child should be observed before finishing layout");
      final child = (sliver as RenderObjectWithChildMixin<RenderBox>).child;

      if (child != null) {
        final model = ItemScrollModel.single(
          child.parentData! as BoxParentData,
          _size!,
          axis: sliver!.constraints.axis,
        );

        models[0] = model;
      }
    }
  }

  Size? _size;

  @override
  void observeSize(ParentData parentData, Size size) {
    assert(parentData is BoxParentData);
    _size = size;
  }

  @override
  double estimateScrollOffset(int target,
      {required double maxScrollExtent, required double minScrollExtent}) {
    // assert(
    //   _origin != null,
    //   "[RevealOffset] should be calculated before estimating the scroll offset for $target."
    //   "Typically, it should happen after $runtimeType.onFinishLayout.",
    // );
    assert(models.isNotEmpty);

    return origin.offset + getItemScrollModel(0)!.mainAxisOffset;
  }

  @override
  ItemScrollModel? getItemScrollModel([int index = 0]) {
    assert(models.isEmpty || models.length == 1);

    return models[0];
  }
}
