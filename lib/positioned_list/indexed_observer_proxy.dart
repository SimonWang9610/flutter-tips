import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class IndexedObserverProxy extends SingleChildRenderObjectWidget {
  final int index;
  const IndexedObserverProxy({
    super.key,
    super.child,
    required this.index,
  });

  @override
  RenderIndexedProxy createRenderObject(BuildContext context) =>
      RenderIndexedProxy(
        index: index,
      );

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderIndexedProxy renderObject) {
    renderObject.index = index;
  }
}

class RenderIndexedProxy extends RenderProxyBox {
  RenderIndexedProxy({
    RenderBox? child,
    required int index,
  }) : _index = index;

  int _index;
  set index(int value) {
    if (_index != value) {
      _index = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    super.performLayout();

    print("[$_index] performLayout: ${parentData?.hashCode}, $size");
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    print("[$_index] paint: $offset, ${parentData}");
  }
}

class IndexedProxyParentData extends BoxParentData {
  int? index;
}
