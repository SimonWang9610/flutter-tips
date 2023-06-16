import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'widget.dart';

enum SlideDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

bool _directionIsMatchAxis(SlideDirection direction, Axis axis) {
  switch (direction) {
    case SlideDirection.leftToRight:
    case SlideDirection.rightToLeft:
      return axis == Axis.horizontal;
    case SlideDirection.topToBottom:
    case SlideDirection.bottomToTop:
      return axis == Axis.vertical;
  }
}

class RenderSlidable extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, SlideActionBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, SlideActionBoxData> {
  RenderSlidable({
    Axis axis = Axis.horizontal,
    SlideDirection direction = SlideDirection.leftToRight,
    required SlideController controller,
    double visibleThreshold = 0.5,
    List<RenderBox>? children,
  })  : _axis = axis,
        _visibleThreshold = visibleThreshold,
        _direction = direction,
        _controller = controller,
        assert(_directionIsMatchAxis(direction, axis),
            "[$direction] does not matched [$axis]") {
    addAll(children);
  }

  Axis _axis;
  Axis get axis => _axis;
  set axis(Axis axis) {
    if (_axis != axis) {
      assert(_directionIsMatchAxis(direction, _axis),
          "[$direction] does not matched [$axis]");
      _axis = axis;
      markNeedsLayout();
    }
  }

  double _visibleThreshold;
  double get visibleThreshold => _visibleThreshold;
  set visibleThreshold(double visibleThreshold) {
    if (_visibleThreshold != visibleThreshold) {
      _visibleThreshold = visibleThreshold;
      markNeedsLayout();
    }
  }

  SlideDirection _direction;
  SlideDirection get direction => _direction;
  set direction(SlideDirection direction) {
    if (_direction != direction) {
      assert(_directionIsMatchAxis(_direction, axis),
          "[$direction] does not matched [$axis]");
      _direction = direction;
      markNeedsLayout();
    }
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
    if (child.parentData is! SlideActionBoxData) {
      child.parentData = SlideActionBoxData();
    }
  }

  /// [firstChild] should be always the main child
  /// other children are action children
  @override
  void performLayout() {
    final mainChildSize = _layoutMainChild();

    _layoutActionChildren(mainChildSize);

    size = mainChildSize;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // if (childCount == 1 && controller.progress == 0) {
    //   context.paintChild(firstChild!, offset);
    //   return;
    // }

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

      if (!child.size.isEmpty) {
        context.paintChild(child, childParentData.offset + offset);
      }

      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  Size _layoutMainChild() {
    final mainChild = firstChild;
    assert(mainChild != null);

    final SlideActionBoxData childParentData =
        mainChild!.parentData as SlideActionBoxData;

    assert(!childParentData.isActionPanel);

    mainChild.layout(constraints, parentUsesSize: true);

    final mainChildSize = mainChild.size;

    final ratio = (1 - visibleThreshold) * controller.value;

    final offset = switch (direction) {
      SlideDirection.leftToRight => Offset(mainChildSize.width * ratio, 0),
      SlideDirection.rightToLeft => Offset(-mainChildSize.width * ratio, 0),
      SlideDirection.topToBottom => Offset(0, mainChildSize.height * ratio),
      SlideDirection.bottomToTop => Offset(0, -mainChildSize.height * ratio),
    };

    childParentData.offset = offset;

    return mainChildSize;
  }

  void _layoutActionChildren(Size mainChildSize) {
    final mainChildData = firstChild?.parentData as SlideActionBoxData?;

    RenderBox? actionChild = mainChildData?.nextSibling;

    if (actionChild == null) {
      return;
    }

    final ratio = (1 - visibleThreshold) * controller.value;

    final mainAxisSpace = switch (axis) {
      Axis.horizontal => mainChildSize.width * ratio / (childCount - 1),
      Axis.vertical => mainChildSize.height * ratio / (childCount - 1),
    };

    final actionConstraints = switch (axis) {
      Axis.horizontal => BoxConstraints.tightFor(
          width: mainAxisSpace,
          height: mainChildSize.height,
        ),
      Axis.vertical => BoxConstraints.tightFor(
          width: mainChildSize.width,
          height: mainAxisSpace,
        ),
    };
    print(
        "actionConstraints: $actionConstraints, progress: ${controller.value}");

    int actionIndex = 0;

    while (actionChild != null) {
      final SlideActionBoxData childParentData =
          actionChild.parentData as SlideActionBoxData;

      assert(childParentData.isActionPanel);

      actionChild.layout(
        actionConstraints,
        parentUsesSize: true,
      );

      childParentData.offset = switch (direction) {
        SlideDirection.leftToRight => Offset(mainAxisSpace * actionIndex, 0),
        SlideDirection.rightToLeft => Offset(
            mainChildSize.width * (1 - ratio) + mainAxisSpace * actionIndex, 0),
        SlideDirection.topToBottom => Offset(0, mainAxisSpace * actionIndex),
        SlideDirection.bottomToTop => Offset(0,
            mainChildSize.height * (1 - ratio) + mainAxisSpace * actionIndex),
      };

      print("size: ${actionChild.size} offset: ${childParentData.offset}");

      actionChild = childParentData.nextSibling;
      actionIndex++;
    }
  }
}

typedef SlideController = ValueListenable<double>;
