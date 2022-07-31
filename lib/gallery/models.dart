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

  bool get isTransitionEnd =>
      animation == null || animation!.status == AnimationStatus.completed;

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

  void updateDragGap({
    required Size gapSize,
    required int start,
    required int end,
    required TranslateDirection direction,
    bool playAnimation = true,
  }) {
    final Offset newTargetOffset = translate(
      start: start,
      end: end,
      direction: direction,
      gapSize: gapSize,
    );

    if (newTargetOffset != targetOffset) {
      targetOffset = newTargetOffset;

      if (playAnimation) {
        animate();
      } else {
        jump();
      }

      rebuild();
    }
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
          nextIndex = (index - 1) >= start ? index - 1 : index + end - start;
          break;
        case TranslateDirection.backward:
          nextIndex = (index + 1) <= end ? index + 1 : index - end + start;
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
      return startOffset;
    }
  }

  void animate() {
    if (animation == null) {
      animation = AnimationController(
        vsync: gridState,
        duration: const Duration(
          milliseconds: 200,
        ),
      )
        ..addListener(rebuild)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            startOffset = targetOffset;
            animation?.dispose();
            animation = null;
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
