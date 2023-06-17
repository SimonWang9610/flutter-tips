import 'package:flutter/rendering.dart';

import 'models.dart';
import 'controller.dart';

class SlideActionBoxData extends ContainerBoxParentData<RenderBox> {
  bool isActionPanel = false;
  bool shouldPaint = true;
}

class RenderSlidable extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, SlideActionBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, SlideActionBoxData> {
  RenderSlidable({
    required SlideController controller,
    required SlideActionLayoutDelegate layoutDelegate,
    List<RenderBox>? children,
  })  : _controller = controller,
        _layoutDelegate = layoutDelegate {
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

  SlideActionLayoutDelegate _layoutDelegate;
  SlideActionLayoutDelegate get layoutDelegate => _layoutDelegate;
  set layoutDelegate(SlideActionLayoutDelegate layoutDelegate) {
    if (_layoutDelegate != layoutDelegate) {
      _layoutDelegate = layoutDelegate;
      markNeedsLayout();
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
    if (child.parentData is! SlideActionBoxData) {
      child.parentData = SlideActionBoxData();
    }
  }

  /// [firstChild] should be always the main child
  /// other children are action children
  @override
  void performLayout() {
    _cachedComputedSizes = _layoutMainChild();

    layoutDelegate.layout(
      _cachedComputedSizes,
      ratio: controller.absoluteRatio,
      axis: controller.axis,
    );

    size = _cachedComputedSizes.mainChildSize;
    controller.size = size;
  }

  late _ComputedSizes _cachedComputedSizes;

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      _paintChildren,
    );
  }

  void _paintChildren(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;

    while (child != null) {
      final childParentData = child.parentData as SlideActionBoxData;

      if (childParentData.shouldPaint) {
        context.paintChild(child, childParentData.offset + offset);
      }

      child = childParentData.nextSibling;
    }

    // final parentData =
    //     _cachedComputedSizes.mainChild.parentData as BoxParentData;

    // context.paintChild(
    //   _cachedComputedSizes.mainChild,
    //   parentData.offset + offset,
    // );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;

    while (child != null) {
      final childParentData = child.parentData as SlideActionBoxData;

      if (childParentData.shouldPaint) {
        final bool isHit = result.addWithPaintOffset(
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
    final (mainChild, preActionCount, postActionCount) = _findTheMainChild();

    final SlideActionBoxData childParentData =
        mainChild.parentData as SlideActionBoxData;

    assert(!childParentData.isActionPanel);

    mainChild.layout(constraints, parentUsesSize: true);

    final mainChildSize = mainChild.size;

    final ratio = controller.absoluteRatio * (1 - controller.visibleThreshold);

    final offset = switch (controller.direction) {
      SlideDirection.leftToRight => Offset(mainChildSize.width * ratio, 0),
      SlideDirection.rightToLeft => Offset(-mainChildSize.width * ratio, 0),
      SlideDirection.topToBottom => Offset(0, mainChildSize.height * ratio),
      SlideDirection.bottomToTop => Offset(0, -mainChildSize.height * ratio),
      SlideDirection.idle => Offset.zero,
    };

    childParentData.offset = offset;

    late final Size sizeForActions;
    late final Size sizeForVisiblePanel;

    switch (controller.axis) {
      case Axis.horizontal:
        sizeForActions = Size(
          mainChildSize.width * (1 - controller.visibleThreshold),
          mainChildSize.height,
        );
        sizeForVisiblePanel = Size(
          mainChildSize.width * controller.visibleThreshold,
          mainChildSize.height,
        );
        break;
      case Axis.vertical:
        sizeForActions = Size(
          mainChildSize.width,
          mainChildSize.height * (1 - controller.visibleThreshold),
        );
        sizeForVisiblePanel = Size(
          mainChildSize.width,
          mainChildSize.height * controller.visibleThreshold,
        );
        break;
    }

    final preActionPoints = switch (controller.direction) {
      SlideDirection.leftToRight || SlideDirection.topToBottom => (
          Offset.zero,
          sizeForActions.bottomRight(Offset.zero),
        ),
      _ => (Offset.zero, Offset.zero),
    };

    final postActionPoints = switch (controller.direction) {
      SlideDirection.rightToLeft => (
          sizeForVisiblePanel.topRight(Offset.zero),
          mainChildSize.bottomRight(Offset.zero),
        ),
      SlideDirection.bottomToTop => (
          sizeForVisiblePanel.bottomLeft(Offset.zero),
          mainChildSize.bottomRight(Offset.zero),
        ),
      _ => (Offset.zero, Offset.zero),
    };

    return _ComputedSizes(
      mainChild: mainChild,
      mainChildSize: mainChildSize,
      preActionPoints: preActionPoints,
      postActionPoints: postActionPoints,
      preActionCount: preActionCount,
      postActionCount: postActionCount,
    );
  }

  (RenderBox, int, int) _findTheMainChild() {
    RenderBox? child = firstChild;

    int preActionCount = 0;
    while (child != null) {
      final childParentData = child.parentData as SlideActionBoxData;

      if (!childParentData.isActionPanel) {
        break;
      }

      preActionCount++;
      child = childParentData.nextSibling;
    }

    return (child!, preActionCount, childCount - preActionCount - 1);
  }
}

typedef PointsForActions = (Offset, Offset);

class _ComputedSizes {
  final RenderBox mainChild;
  final Size mainChildSize;
  final PointsForActions preActionPoints;
  final PointsForActions postActionPoints;
  final int preActionCount;
  final int postActionCount;

  const _ComputedSizes({
    required this.mainChild,
    required this.mainChildSize,
    required this.preActionPoints,
    required this.postActionPoints,
    required this.preActionCount,
    required this.postActionCount,
  });

  /// all actions would be laid out with the same [BoxConstraints]
  /// that is averaged by the specific action count
  /// [layoutRatio] determines how many the ratio of the rect would be used to calculate the constraints
  LayoutSizeForAction getActionLayout(
    Axis axis, {
    required ActionPosition position,
    double layoutRatio = 1.0,
  }) {
    final topLeft = position == ActionPosition.pre
        ? preActionPoints.$1
        : postActionPoints.$1;

    final bottomRight = position == ActionPosition.pre
        ? preActionPoints.$2
        : postActionPoints.$2;

    final actionCount =
        position == ActionPosition.pre ? preActionCount : postActionCount;

    final rect = Rect.fromPoints(topLeft, bottomRight);
    final constraints = rect.getConstraints(axis, layoutRatio, actionCount);
    final averageShift = rect.getShiftedOffset(axis, actionCount, layoutRatio);

    return LayoutSizeForAction(
      topLeft: topLeft,
      bottomRight: bottomRight,
      averageShift: averageShift,
      constraints: constraints,
      position: position,
    );
  }

  @override
  String toString() {
    return '_ComputedSizes{mainChildSize: $mainChildSize, preActionPoints: $preActionPoints, postActionPoints: $postActionPoints, preActionCount: $preActionCount, postActionCount: $postActionCount}';
  }
}

class SlideActionLayoutDelegate {
  void layout(
    _ComputedSizes computedSized, {
    double ratio = 0.0,
    Axis axis = Axis.horizontal,
  }) {
    final preActionLayout = computedSized.getActionLayout(
      axis,
      position: ActionPosition.pre,
    );

    final postActionLayout = computedSized.getActionLayout(
      axis,
      position: ActionPosition.post,
    );

    // print(preActionLayout);
    // print(postActionLayout);

    int preIndex = computedSized.preActionCount - 1;
    RenderBox? preChild = _childBefore(computedSized.mainChild);

    while (preChild != null) {
      final childSize =
          ChildLayoutHelper.layoutChild(preChild, preActionLayout.constraints);

      final childParentData = preChild.parentData as SlideActionBoxData;

      childParentData.offset =
          preActionLayout.getRelativeOffset(preIndex, ratio);
      childParentData.shouldPaint = !childSize.isEmpty;

      preChild = _childBefore(preChild);
      preIndex--;
    }

    assert(preIndex == -1);

    int postIndex = computedSized.postActionCount - 1;
    RenderBox? postChild = _childAfter(computedSized.mainChild);

    while (postChild != null) {
      final childSize = ChildLayoutHelper.layoutChild(
          postChild, postActionLayout.constraints);

      final childParentData = postChild.parentData as SlideActionBoxData;

      childParentData.offset =
          postActionLayout.getRelativeOffset(postIndex, ratio);
      childParentData.shouldPaint = !childSize.isEmpty;

      postChild = _childAfter(postChild);
      postIndex--;
    }
    assert(postIndex == -1);
  }

  RenderBox? _childBefore(RenderBox? child) {
    if (child == null) return null;
    final parentData = child.parentData as SlideActionBoxData;

    return parentData.previousSibling;
  }

  RenderBox? _childAfter(RenderBox? child) {
    if (child == null) return null;
    final parentData = child.parentData as SlideActionBoxData;

    return parentData.nextSibling;
  }
}
