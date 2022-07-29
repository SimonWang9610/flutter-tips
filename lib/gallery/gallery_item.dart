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
    with SingleTickerProviderStateMixin {
  late GridGalleryState _gridState;

  AnimationController? _controller;

  /// the effective index during dragging
  late int _movingIndex = widget.index;

  /// the translation offset during dragging
  Offset _startOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;

  Size? _itemSize;

  ValueKey<int> get key => ValueKey<int>(widget.index);
  int get index => widget.index;
  int get movingIndex => _movingIndex;
  GridGalleryState get gridState => _gridState;
  Offset get transitionOffset => _targetOffset;
  bool get isTransitionCompleted =>
      _controller == null || _controller!.status == AnimationStatus.completed;

  Offset get offset {
    if (_controller != null) {
      final double animatedValue = widget.curve.transform(_controller!.value);

      return Offset.lerp(_startOffset, _targetOffset, animatedValue)!;
    }
    return _targetOffset;
  }

  Rect get geometry {
    final box = context.findRenderObject() as RenderBox;
    final Offset itemPosition = box.localToGlobal(Offset.zero);

    if (_itemSize != box.size) {
      _itemSize = box.size;
    }

    return (itemPosition - _targetOffset) & _itemSize!;
  }

  @override
  void initState() {
    super.initState();
    _gridState = GridGallery.of(context);
    _gridState.registerItem(index, this);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _gridState.unregisterItem(index, this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GalleryItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // print('update: from ${oldWidget.index} to ${widget.index}');

    if (oldWidget.index != widget.index) {
      _gridState.unregisterItem(oldWidget.index, this);
      _gridState.registerItem(index, this);
    }
  }

  @override
  void deactivate() {
    _gridState.unregisterItem(index, this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = context.findRenderObject() as RenderBox;

      _itemSize = box.size;
    });

    _gridState.registerItem(_movingIndex, this);

    return Transform.translate(
      offset: offset,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(),
        ),
        child: GalleryItemDragStartListener(
          index: _movingIndex,
          child: widget.child,
        ),
      ),
    );
  }

  /// if [movingIndex] is between [start] and [end], we should move it during dragging
  void updateDrag(int start, int end, bool startDrag, {bool animate = true}) {
    final bool notMoving =
        startDrag || _movingIndex < start || _movingIndex > end;

    final int targetIndex =
        notMoving ? index : (start == _movingIndex ? end : _movingIndex - 1);

    final Offset newTargetOffset = extentOffset(targetIndex);

    _movingIndex = targetIndex;

    if (_targetOffset != newTargetOffset) {
      // print('$index: $_targetOffset -> $newTargetOffset');
      _targetOffset = newTargetOffset;

      if (animate) {
        _animateTo(targetIndex);
      } else {
        _jumpTo(targetIndex);
      }
    }
  }

  void _animateTo(int targetIndex) {
    _movingIndex = targetIndex;

    if (_controller == null) {
      _controller = AnimationController(
        vsync: _gridState,
        duration: const Duration(milliseconds: 200),
      )
        ..addListener(rebuild)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _startOffset = _targetOffset;
            _controller?.dispose();
            _controller = null;
          }
        })
        ..forward();
    } else {
      // it may trigger animation before the previous animation is completed
      _startOffset = offset;

      _controller!.forward(from: 0);
    }
  }

  void _jumpTo(int targetIndex) {
    _movingIndex = targetIndex;

    _controller?.dispose();
    _controller = null;
    _startOffset = _targetOffset;
    rebuild();
  }

  Offset extentOffset(int targetIndex) {
    // TODO: should sync [_itemSize]?

    if (targetIndex == _movingIndex) return Offset.zero;

    final Axis mainAxis = _gridState.widget.scrollDirection;
    final crossAxisCount = _gridState.crossAxisCount;

    final int verticalStep =
        targetIndex ~/ crossAxisCount - _movingIndex ~/ crossAxisCount;
    final int horizontalStep =
        targetIndex % crossAxisCount - _movingIndex % crossAxisCount;

    double verticalSpacing = 0.0;
    double horizontalSpacing = 0.0;

    switch (mainAxis) {
      case Axis.vertical:
        verticalSpacing = _gridState.mainAxisSpacing;
        horizontalSpacing = _gridState.crossAxisSpacing;
        break;
      case Axis.horizontal:
        verticalSpacing = _gridState.crossAxisSpacing;
        horizontalSpacing = _gridState.mainAxisSpacing;
        break;
    }

    final double dy = verticalStep * (_itemSize!.height + verticalSpacing);
    final double dx = horizontalStep * (_itemSize!.width + horizontalSpacing);

    return Offset(dx, dy);
  }

  void rebuild() {
    setState(() {});
  }

  void resetTranslation() {
    _controller?.dispose();
    _controller = null;
    _startOffset = Offset.zero;
    _targetOffset = Offset.zero;
    _movingIndex = index;
    rebuild();
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
