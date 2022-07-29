import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tips/gallery/gallery_drag.dart';
import 'package:flutter_tips/gallery/gallery_item.dart';

class GridGallery extends StatefulWidget {
  final int crossAxisCount;
  final List<Widget> galleries;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final int maxCount;
  final Axis scrollDirection;
  const GridGallery({
    Key? key,
    required this.galleries,
    this.scrollDirection = Axis.vertical,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 5.0,
    this.mainAxisSpacing = 5.0,
    this.maxCount = 9,
  }) : super(key: key);

  @override
  State<GridGallery> createState() => GridGalleryState();

  static GridGalleryState of(BuildContext context) {
    final state = context.findAncestorStateOfType<GridGalleryState>();

    assert(state != null, "No [GridGalleryState] found.");
    return state!;
  }

  static GridGalleryState? mayOf(BuildContext context) {
    final state = context.findAncestorStateOfType<GridGalleryState>();
    return state!;
  }
}

class GridGalleryState extends State<GridGallery>
    with TickerProviderStateMixin {
  final Map<int, GalleryItemWidgetState> _items = {};

  /// [_draggingOverlay] used to display the dragging [GalleryItem]
  OverlayEntry? _draggingOverlay;

  /// [_recognizer] used to detect the drag gesture and trigger [_startDrag] when [MultiDragGestureRecognizer.onStart]
  MultiDragGestureRecognizer? _recognizer;

  /// [_drag] used to track the last drag operation
  /// also responsible for listening to [_onDragUpdate], [_onDragCompleted]
  /// [_onDragCancel] and [_onDragEnd]
  GalleryItemDrag? _drag;

  /// the index of the item dragging
  /// it would be reset after [_onDragCompleted]
  int? _dragIndex;

  /// the index that the dragging item will be inserted into after [_onDragCompleted]
  int? _targetIndex;

  Offset? _finalDropPosition;
  Offset? get finalDropPosition => _finalDropPosition;

  int get crossAxisCount => widget.crossAxisCount;
  int get maxCount => widget.maxCount;
  double get crossAxisSpacing => widget.crossAxisSpacing;
  double get mainAxisSpacing => widget.mainAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return GridView(
      scrollDirection: widget.scrollDirection,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      children: [
        for (int i = 0; i < widget.galleries.length; i++)
          GalleryItemWidget(
            key: ValueKey(i),
            index: i,
            child: widget.galleries[i],
          ),
        if (widget.galleries.length < widget.maxCount) _addItem(),
      ],
    );
  }

  Widget _addItem() {
    return IconButton(
      onPressed: () {
        final length = widget.galleries.length;

        final gallery = Text('$length');

        widget.galleries.add(gallery);
        setState(() {});
      },
      icon: const Icon(
        Icons.add,
      ),
    );
  }

  /// register [item] so as to it could be translated by [_translateItems] when
  /// [_onDragUpdate] and also allow [GridGallery] to control its rebuild.
  void registerItem(int index, GalleryItemWidgetState item) {
    _items[index] = item;
  }

  /// only unregister the item if the [index] is matched to [item]
  void unregisterItem(int index, GalleryItemWidgetState item) {
    final targetItem = _items[index];

    if (targetItem == item) {
      _items.remove(index);
    }
  }

  /// [GalleryItemDragStartListener] will call this to register [_drag]
  /// and thus response to [_onDragUpdate] after [MultiDragGestureRecognizer.onStart]
  void startItemDragging({
    required int index,
    required PointerDownEvent event,
    required MultiDragGestureRecognizer recognizer,
  }) {
    assert(index >= 0 && index < widget.galleries.length);

    cleanDragIfNecessary(event);

    if (_items.containsKey(index)) {
      _dragIndex = index;
      _recognizer = recognizer
        ..onStart = _startDrag
        ..addPointer(event);
    } else {
      throw Exception(
          'Attempting to start a drag on a non-visible item: $index');
    }
  }

  /// clean the previous drag operation
  void cleanDragIfNecessary(PointerDownEvent event) {
    if (_drag != null) {
      // cancel the previous drag
      _resetDrag();
    } else if (_recognizer != null) {
      // reset the previous recognizer
      _recognizer?.dispose();
      _recognizer = null;
    }
  }

  /// 1) register [_drag] to handle [_onDragCancel], [_onDragUpdate] and [_onDragEnd]
  /// 2) also build [_draggingOverlay] to display the dragging item
  /// 3) notify items the drag is starting by [GalleryItemWidgetState.updateDrag]
  Drag? _startDrag(Offset position) {
    assert(_drag == null);

    final item = _items[_dragIndex]!;

    _targetIndex = item.index;

    _drag = GalleryItemDrag(
      item: item,
      initialPosition: position,
      onDragCancel: _onDragCancel,
      onDragEnd: _onDragEnd,
      onDragUpdate: _onDragUpdate,
    );

    _draggingOverlay = OverlayEntry(builder: _drag!.buildOverlay);
    Overlay.of(context)?.insert(_draggingOverlay!);

    for (final childItem in _items.values) {
      // if (childItem == item || !childItem.mounted) continue;
      childItem.updateDrag(_targetIndex!, _targetIndex!, true, animate: false);
    }
    return _drag;
  }

  /// when the [_drag] updates the [GalleryItemDrag.dragPosition]
  /// [_draggingOverlay] must be moved the new position
  /// [_items] should also be translated temporarily before [_onDragCompleted]
  void _onDragUpdate(GalleryItemDrag drag, Offset position, Offset delta) {
    _draggingOverlay?.markNeedsBuild();
    _translateItems();
  }

  // TODO: allow more callbacks
  void _onDragEnd(GalleryItemDrag drag) {
    _onDragCompleted();
  }

  void _onDragCancel(GalleryItemDrag drag) {
    _resetDrag();
  }

  /// before the drag is completed, all items are translated temporarily
  /// once the drag is completed, items finally are swapped
  void _onDragCompleted() {
    final int fromIndex = _dragIndex!;
    final int toIndex = _targetIndex!;

    print('drag completed: $fromIndex -> $toIndex ');

    final gallery = widget.galleries.removeAt(fromIndex);

    widget.galleries.insert(toIndex, gallery);

    _resetDrag();
  }

  /// no matter [_drag] is completed or canceled
  /// all resources are used to listen and handle drag details should be restore
  /// particularly, we must [_resetItemTranslation] to clean the temporary information during dragging
  /// and prepare them for subsequent drag operations
  /// otherwise, the items may not be translated correctly during subsequent dragging
  /// due to the wrong [GalleryItemWidgetState.offset]
  /// and unmatched index between [GalleryItemWidgetState.index] and [GalleryItemWidgetState.movingIndex]
  void _resetDrag() {
    if (_drag != null) {
      if (_dragIndex != null && _items.containsKey(_dragIndex)) {
        final item = _items[_dragIndex]!;
        item.rebuild();
        _dragIndex = null;
      }

      _drag = null;
      _recognizer?.dispose();
      _resetItemTranslation();
      _recognizer = null;
      _draggingOverlay?.remove();
      _draggingOverlay = null;
      _finalDropPosition = null;
      _targetIndex = null;
    }

    setState(() {});
  }

  /// when dragging, the effective index is [GalleryItemWidgetState.movingIndex]
  /// while the real index is [GalleryItemWidgetState.index]
  /// so [_targetIndex] should be the item's real index
  /// but we compare their effective indexes between items and the dragging item during dragging
  void _translateItems() {
    assert(_drag != null);

    int newTargetIndex = _targetIndex!;

    // find the item containing the the drag position as the drop target
    for (final item in _items.values) {
      if (item.movingIndex == _dragIndex || !item.mounted) continue;

      Rect itemGeometry = item.geometry;

      if (!item.isTransitionCompleted && item.movingIndex >= _dragIndex!) {
        itemGeometry =
            (itemGeometry.topLeft - item.transitionOffset) & itemGeometry.size;
      }

      if (itemGeometry.contains(_drag!.dragPosition)) {
        newTargetIndex = item.index;
      }
    }

    assert(_dragIndex != null && _targetIndex != null);

    // update drag info for each if the drop target is not the dragging item
    if (newTargetIndex != _targetIndex) {
      _targetIndex = newTargetIndex;

      final int? start =
          _dragIndex! > _targetIndex! ? _targetIndex : _dragIndex;
      final int? end = _dragIndex! > _targetIndex! ? _dragIndex : _targetIndex;

      for (final item in _items.values) {
        item.updateDrag(start!, end!, false);
      }
    }
  }

  void _resetItemTranslation() {
    for (final item in _items.values) {
      item.resetTranslation();
    }
  }
}
