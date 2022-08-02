import 'package:flutter/material.dart';
import 'package:flutter_tips/gallery/grid_gallery.dart';

mixin GalleryItemDragDelegate<T extends StatefulWidget> on State<T> {
  late GridGalleryState gridState;
  bool isDragging = false;

  Size? size;
  Offset startOffset = Offset.zero;
  Offset targetOffset = Offset.zero;

  int get index;
  Curve get curve;
  AnimationController? get animation;
  set animation(AnimationController? value);

  bool get isTransitionEnd => animation == null;

  Offset get offset {
    if (animation != null) {
      final double t = curve.transform(animation!.value);

      return Offset.lerp(startOffset, targetOffset, t)!;
    }
    return targetOffset;
  }

  Rect get geometry {
    final box = context.findRenderObject() as RenderBox;
    final Offset itemPosition = box.localToGlobal(Offset.zero);

    size = box.size;

    return itemPosition & size!;
  }

  Rect get translatedGeometry {
    return geometry.translate(targetOffset.dx, targetOffset.dy);
  }

  void apply({
    required int moving,
    required Size gapSize,
    bool playAnimation = true,
  }) {
    translateTo(moving: moving, gapSize: gapSize);

    if (playAnimation) {
      animate();
    } else {
      jump();
    }
    rebuild();
  }

  void translateTo({required int moving, required Size gapSize}) {
    if (index == moving) {
      targetOffset = Offset.zero;
      return;
    }

    final Offset original = gridState.calculateItemCoordinate(index);
    final Offset target = gridState.calculateItemCoordinate(moving);

    final Axis mainAxis = gridState.widget.scrollDirection;

    double verticalSpacing = 0.0;
    double horizontalSpacing = 0.0;

    switch (mainAxis) {
      case Axis.vertical:
        verticalSpacing = gridState.mainAxisSpacing;
        horizontalSpacing = gridState.crossAxisSpacing;
        break;
      case Axis.horizontal:
        verticalSpacing = gridState.crossAxisSpacing;
        horizontalSpacing = gridState.mainAxisSpacing;
        break;
    }

    targetOffset = (target - original).scale(
        gapSize.width + horizontalSpacing, gapSize.height + verticalSpacing);
  }

  Offset translate({
    required int start,
    required int end,
    required TranslateDirection direction,
    required Size gapSize,
  }) {
    final bool needTranslate = index >= start && index <= end;

    if (needTranslate) {
      final Offset current = gridState.calculateItemCoordinate(index);

      int nextIndex = index;

      switch (direction) {
        case TranslateDirection.forward:
          nextIndex =
              (nextIndex - 1) >= start ? nextIndex - 1 : index + end - start;
          break;
        case TranslateDirection.backward:
          nextIndex =
              (nextIndex + 1) <= end ? nextIndex + 1 : index - end + start;
          break;
      }

      final Offset target = gridState.calculateItemCoordinate(nextIndex);

      final Axis mainAxis = gridState.widget.scrollDirection;

      double verticalSpacing = 0.0;
      double horizontalSpacing = 0.0;

      switch (mainAxis) {
        case Axis.vertical:
          verticalSpacing = gridState.mainAxisSpacing;
          horizontalSpacing = gridState.crossAxisSpacing;
          break;
        case Axis.horizontal:
          verticalSpacing = gridState.crossAxisSpacing;
          horizontalSpacing = gridState.mainAxisSpacing;
          break;
      }

      return (target - current).scale(
          gapSize.width + horizontalSpacing, gapSize.height + verticalSpacing);
    } else {
      return targetOffset;
    }
  }

  void animate() {
    if (animation == null) {
      animation = AnimationController(
        vsync: gridState,
        duration: const Duration(
          milliseconds: 100,
        ),
      )
        ..addListener(rebuild)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            startOffset = targetOffset;
            animation?.dispose();
            animation = null;
            rebuild();
          }
        })
        ..forward();
    } else {
      startOffset = offset;
      animation?.forward(from: 0);
    }
  }

  void jump() {
    animation?.dispose();
    animation = null;
    startOffset = targetOffset;
    // rebuild();
  }

  void rebuild() {
    setState(() {});
  }

  void reset() {
    animation?.dispose();
    animation = null;
    startOffset = Offset.zero;
    targetOffset = Offset.zero;
    isDragging = false;
    rebuild();
  }
}

enum TranslateDirection { forward, backward }
