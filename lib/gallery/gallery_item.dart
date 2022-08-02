import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'grid_gallery.dart';

class GalleryItemWidget extends StatefulWidget {
  final int index;
  final Widget child;
  final Curve curve;
  const GalleryItemWidget({
    Key? key,
    required this.child,
    required this.index,
    this.curve = Curves.easeIn,
  }) : super(key: key);

  @override
  State<GalleryItemWidget> createState() => GalleryItemWidgetState();
}

class GalleryItemWidgetState extends State<GalleryItemWidget>
    with GalleryItemDragDelegate {
  AnimationController? _controller;

  ValueKey<int> get key => ValueKey<int>(widget.index);
  @override
  int get index => widget.index;
  @override
  Curve get curve => widget.curve;

  @override
  AnimationController? get animation => _controller;

  @override
  set animation(AnimationController? value) => _controller = value;

  bool get isTransitionCompleted =>
      _controller == null || _controller!.status == AnimationStatus.completed;

  @override
  void initState() {
    super.initState();

    gridState = GridGallery.of(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GalleryItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // print('update: from ${oldWidget.index} to ${widget.index}');

    if (oldWidget.index != widget.index) {
      gridState.unregisterItem(oldWidget.index, this);
      gridState.registerItem(this);
    }
  }

  @override
  void deactivate() {
    gridState.unregisterItem(index, this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = context.findRenderObject() as RenderBox;

      size = box.size;
    });

    gridState.registerItem(this);

    if (isDragging) {
      return const SizedBox();
    }

    return GalleryItemDragStartListener(
      index: index,
      child: Transform.translate(
        offset: offset,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: Align(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class GalleryItemDragStartListener extends StatelessWidget {
  final int index;
  final Widget child;
  final bool enabled;
  const GalleryItemDragStartListener({
    Key? key,
    required this.index,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: enabled ? (event) => _startDragging(context, event) : null,
      child: child,
    );
  }

  MultiDragGestureRecognizer createRecognizer() {
    return ImmediateMultiDragGestureRecognizer(debugOwner: this);
  }

  void _startDragging(BuildContext context, PointerDownEvent event) {
    final DeviceGestureSettings? gestureSetting =
        MediaQuery.maybeOf(context)?.gestureSettings;

    final GridGalleryState? grid = GridGallery.mayOf(context);

    grid?.startItemDragging(
      index: index,
      event: event,
      recognizer: createRecognizer()..gestureSettings = gestureSetting,
    );
  }
}

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

  /// return the original [RenderBox]'s top-left
  /// the effective geometry should be (itemPosition - targetOffset) & size!
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
        verticalSpacing = gridState.widget.mainAxisSpacing;
        horizontalSpacing = gridState.widget.crossAxisSpacing;
        break;
      case Axis.horizontal:
        verticalSpacing = gridState.widget.crossAxisSpacing;
        horizontalSpacing = gridState.widget.mainAxisSpacing;
        break;
    }

    targetOffset = (target - original).scale(
        gapSize.width + horizontalSpacing, gapSize.height + verticalSpacing);
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
