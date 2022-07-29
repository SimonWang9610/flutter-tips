import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tips/gallery/gallery_item.dart';
import 'package:flutter_tips/gallery/grid_gallery.dart';

typedef GalleryItemDragUpdate = void Function(GalleryItemDrag, Offset, Offset);
typedef GalleryItemDragCallback = void Function(GalleryItemDrag);

Offset _overlayOrigin(BuildContext context) {
  final OverlayState overlay = Overlay.of(context)!;
  final RenderBox overlayBox = overlay.context.findRenderObject()! as RenderBox;
  return overlayBox.localToGlobal(Offset.zero);
}

class GalleryItemDrag extends Drag {
  late GridGalleryState gridState;
  late int index;
  late Widget child;
  late Offset dragPosition;
  late Offset dragOffset;
  late Size itemSize;

  final GalleryItemDragUpdate? onDragUpdate;
  final GalleryItemDragCallback? onDragEnd;
  final GalleryItemDragCallback? onDragCancel;

  GalleryItemDrag({
    required GalleryItemWidgetState item,
    Offset initialPosition = Offset.zero,
    this.onDragUpdate,
    this.onDragCancel,
    this.onDragEnd,
  }) {
    final itemBox = item.context.findRenderObject()! as RenderBox;

    gridState = item.gridState;
    index = item.index;
    child = item.widget.child;
    dragPosition = initialPosition;
    dragOffset = itemBox.globalToLocal(initialPosition);
    itemSize = itemBox.size;
  }

  @override
  void update(DragUpdateDetails details) {
    final Offset delta = details.delta;

    dragPosition += delta;
    onDragUpdate?.call(this, dragPosition, details.delta);
  }

  @override
  void end(DragEndDetails details) {
    onDragEnd?.call(this);
  }

  @override
  void cancel() {
    onDragCancel?.call(this);
  }

  Widget buildOverlay(BuildContext context) {
    return DraggingItemOverlay(
      gridState: gridState,
      index: index,
      position: dragPosition - dragOffset - _overlayOrigin(context),
      size: itemSize,
      child: child,
    );
  }
}

class DraggingItemOverlay extends StatelessWidget {
  final GridGalleryState gridState;
  final int index;
  final Widget child;
  final Offset position;
  final Size size;
  const DraggingItemOverlay({
    Key? key,
    required this.gridState,
    required this.child,
    required this.index,
    required this.position,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: SizedBox.fromSize(
        size: size,
        child: child,
      ),
    );
  }
}
