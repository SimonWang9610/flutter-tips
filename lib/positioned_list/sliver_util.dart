import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tips/positioned_list/item_proxy.dart';

class SliverUtil {
  static List<RenderSliverMultiBoxAdaptor> findSlivers(
      RenderViewportBase viewport) {
    // assert(
    //     !viewport.attached, "The given [RenderViewportBase] is not attached");

    final List<RenderSliverMultiBoxAdaptor> slivers = [];

    void findSliver(RenderObject renderObject) {
      if (renderObject is RenderSliverMultiBoxAdaptor) {
        final hasProxyChild = renderObject.firstChild is RenderSliverItem;
        if (hasProxyChild) {
          slivers.add(renderObject);
        }
        return;
      } else if (renderObject is RenderSliver) {
        renderObject.visitChildren(findSliver);
      }
    }

    // slivers must have the same order as they are in the render object tree
    viewport.visitChildren(findSliver);

    return slivers;
  }

  static RenderViewportBase findViewportBase(BuildContext context) {
    RenderViewportBase? viewport;

    void findViewport(Element element) {
      if (viewport != null) return;

      if (element is RenderObjectElement &&
          element.renderObject is RenderViewportBase) {
        viewport = element.renderObject as RenderViewportBase;
        return;
      } else {
        element.visitChildren(findViewport);
      }
    }

    context.visitChildElements(findViewport);

    // assert(viewport != null || !viewport!.attached,
    //     "The given $context has no [RenderViewportBase] found. Or the found [RenderViewportBase] has been detached");

    return viewport!;
  }

  static RenderViewportBase findViewport(RenderSliver sliver,
      {int maxTraceCount = 5}) {
    AbstractNode? viewport = sliver.parent;

    int traceCount = 0;

    while (traceCount < maxTraceCount) {
      if (viewport is RenderViewportBase) {
        break;
      } else {
        viewport = viewport!.parent;
        traceCount++;
      }
    }

    assert(
      viewport != null,
      "Not found a [RenderViewportBase] ancestor for $sliver in the tracing depth: $maxTraceCount. If you ensure the sliver has a [RenderViewportBase] ancestor, you could increase [maxTraceCount] to allow trace more ancestor nodes",
    );

    return viewport! as RenderViewportBase;
  }
}
