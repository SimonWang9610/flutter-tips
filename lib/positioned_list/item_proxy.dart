import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'observer/scroll_observer.dart';
import 'observer/single_child_observer.dart';

class ItemProxy extends SingleChildRenderObjectWidget {
  final ScrollObserver? observer;
  const ItemProxy({
    super.key,
    super.child,
    required this.observer,
  });

  @override
  RenderSliverItem createRenderObject(BuildContext context) => RenderSliverItem(
        observer: observer,
      );

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderSliverItem renderObject) {
    renderObject.observer = observer;
  }
}

class RenderSliverItem extends RenderProxyBox {
  RenderSliverItem({
    RenderBox? child,
    ScrollObserver? observer,
  })  : _observer = observer,
        super(child);

  ScrollObserver? _observer;

  set observer(ScrollObserver? newObserver) {
    if (_observer == newObserver) return;
    _observer = newObserver;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    super.performLayout();

    final sliver = _findParentSliver();

    if (sliver != null) {
      _observer?.onLayout(sliver);
      _observer?.observeSize(parentData!, size);

      // [RenderSliverMultiBoxAdaptor] would notify the layout is finished
      //? however, if the single child render sliver would finish layout here
      if (_observer != null && _observer is SingleChildScrollObserver) {
        _observer?.onFinishLayout(0, 0);
      }
    }
  }

  RenderSliver? _findParentSliver() {
    if (child == null || _observer == null) return null;

    AbstractNode? parentSliver = parent;

    int traceCount = 0;

    while (traceCount < _kMaxTraceDepth && parentSliver is RenderObject) {
      if (parentSliver is RenderSliver) {
        break;
      } else {
        parentSliver = parentSliver.parent;
        traceCount++;
      }
    }
    if (parentSliver == null || parentSliver is! RenderSliver) return null;
    return parentSliver;
  }
}

const int _kMaxTraceDepth = 4;
