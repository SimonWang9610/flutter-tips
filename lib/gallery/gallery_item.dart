import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tips/gallery/models.dart';
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
            // alignment: Alignment.topLeft +
            //     Alignment(
            //       index / gridState.totalItem * 2,
            //       index / gridState.totalItem * 2,
            //     ),
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
