import 'package:flutter/rendering.dart';
import 'package:flutter_tips/slidable/action_render.dart';

import 'models.dart';
import 'controller.dart';

class SlidableBoxData extends ContainerBoxParentData<RenderBox> {
  ActionPosition? position;
}

class RenderSlidable extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, SlidableBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, SlidableBoxData> {
  RenderSlidable({
    required SlideController controller,
    List<RenderBox>? children,
  }) : _controller = controller {
    addAll(children);
  }

  SlideController _controller;
  SlideController get controller => _controller;
  set controller(SlideController controller) {
    if (_controller != controller) {
      final oldController = _controller;

      _controller = controller;

      if (attached) {
        oldController.removeListener(markNeedsLayout);
        _controller.addListener(markNeedsLayout);
      }
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _controller.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! SlidableBoxData) {
      child.parentData = SlidableBoxData();
    }
  }

  /// [firstChild] should be always the main child
  /// other children are action children
  @override
  void performLayout() {
    assert(childCount <= 3);

    print("layout RenderSlidable");

    final computedSize = _layoutMainChild();

    RenderBox? child = firstChild;

    while (child != null) {
      final childParentData = child.parentData as SlidableBoxData;

      if (childParentData.position != null) {
        final actionConstraints = switch (childParentData.position!) {
          ActionPosition.pre => computedSize.constraintsForPreAction,
          ActionPosition.post => computedSize.constraintsForPostAction,
        };

        child.layout(actionConstraints, parentUsesSize: false);

        childParentData.offset = switch (childParentData.position!) {
          ActionPosition.pre => Offset.zero,
          ActionPosition.post =>
            computedSize.getTopLeftForPostAction(controller.axis),
        };
      }

      child = childParentData.nextSibling;
    }

    size = computedSize.size;
    controller.layoutSize = computedSize.layoutSize;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;

    while (child != null) {
      final childParentData = child.parentData as SlidableBoxData;

      if (!child.size.isEmpty) {
        final isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset? transformed) {
            assert(transformed == position - childParentData.offset);
            return child!.hitTest(result, position: transformed!);
          },
        );

        if (isHit) {
          return true;
        }
      }

      child = childParentData.previousSibling;
    }

    return false;
  }

  _ComputedSizes _layoutMainChild() {
    final (mainChild, hasPreAction, hasPostAction) = _findTheMainChild();

    final mainChildSize = ChildLayoutHelper.layoutChild(mainChild, constraints);

    final ratioForAction = controller.maxSlideThreshold;
    final visibleRatio = controller.ratio * ratioForAction;

    final offset = switch (controller.axis) {
      Axis.horizontal => Offset(mainChildSize.width * visibleRatio, 0),
      Axis.vertical => Offset(0, mainChildSize.height * visibleRatio),
    };

    final mainChildParentData = mainChild.parentData as BoxParentData;
    mainChildParentData.offset = offset;

    final sizeForAction = switch (controller.axis) {
      Axis.horizontal =>
        Size(mainChildSize.width * ratioForAction, mainChildSize.height),
      Axis.vertical =>
        Size(mainChildSize.width, mainChildSize.height * ratioForAction),
    };

    final showingPreActions = controller.ratio > 0;
    final showingPostActions = controller.ratio < 0;

    final emptyConstraints = BoxConstraints.tight(Size.zero);

    return _ComputedSizes(
      size: mainChildSize,
      topLeft: offset,
      constraintsForPreAction: showingPreActions
          ? BoxConstraints.tight(sizeForAction)
          : emptyConstraints,
      constraintsForPostAction: showingPostActions
          ? BoxConstraints.tight(sizeForAction)
          : emptyConstraints,
      hasPreAction: hasPreAction,
      hasPostAction: hasPostAction,
    );
  }

  (RenderBox, bool, bool) _findTheMainChild() {
    RenderBox? child = firstChild;

    RenderBox? mainChild;

    bool hasPreAction = false;
    bool hasPostAction = false;

    while (child != null) {
      final childParentData = child.parentData as SlidableBoxData;

      if (child is RenderSlideAction) {
        final position =
            mainChild == null ? ActionPosition.pre : ActionPosition.post;
        childParentData.position = position;

        if (position == ActionPosition.pre) {
          hasPreAction = true;
        } else {
          hasPostAction = true;
        }
      } else {
        mainChild = child;
      }

      child = childParentData.nextSibling;
    }

    assert(mainChild != null);

    return (mainChild!, hasPreAction, hasPostAction);
  }
}

class _ComputedSizes {
  final Size size;
  final Offset topLeft;
  final BoxConstraints constraintsForPreAction;
  final BoxConstraints constraintsForPostAction;
  final bool hasPreAction;
  final bool hasPostAction;

  const _ComputedSizes({
    required this.size,
    required this.topLeft,
    required this.constraintsForPostAction,
    required this.constraintsForPreAction,
    required this.hasPreAction,
    required this.hasPostAction,
  });

  Offset getTopLeftForPostAction(Axis axis) {
    return switch (axis) {
      Axis.horizontal => size.topRight(topLeft),
      Axis.vertical => size.bottomLeft(topLeft),
    };
  }

  LayoutSize get layoutSize => LayoutSize(
        size: size,
        hasPreAction: hasPreAction,
        hasPostAction: hasPostAction,
      );

  @override
  String toString() {
    return '_ComputedSizes(size: $size, topLeft: $topLeft, constraintsForPreAction: $constraintsForPreAction, constraintsForPostAction: $constraintsForPostAction, hasPreAction: $hasPreAction, hasPostAction: $hasPostAction)';
  }
}
