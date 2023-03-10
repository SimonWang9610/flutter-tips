import 'package:flutter/rendering.dart';

class ItemScrollModel {
  final int index;
  final double mainAxisOffset;
  final Size size;
  final double? crossAxisOffset;

  ItemScrollModel({
    required this.index,
    required this.mainAxisOffset,
    required this.crossAxisOffset,
    required this.size,
  });

  factory ItemScrollModel.multi(
      SliverMultiBoxAdaptorParentData parentData, Size size) {
    return ItemScrollModel(
      index: parentData.index!,
      mainAxisOffset: parentData.layoutOffset!,
      crossAxisOffset: parentData is SliverGridParentData
          ? parentData.crossAxisOffset!
          : null,
      size: size,
    );
  }

  factory ItemScrollModel.single(BoxParentData parentData, Size size,
      {required Axis axis}) {
    double mainAxisOffset = 0.0;
    double crossAxisOffset = 0.0;

    switch (axis) {
      case Axis.vertical:
        mainAxisOffset = parentData.offset.dy;
        crossAxisOffset = parentData.offset.dx;
        break;
      case Axis.horizontal:
        mainAxisOffset = parentData.offset.dx;
        crossAxisOffset = parentData.offset.dy;
        break;
    }

    return ItemScrollModel(
      index: 0,
      mainAxisOffset: mainAxisOffset,
      crossAxisOffset: crossAxisOffset,
      size: size,
    );
  }

  double getTrailingOffset(Axis axis) {
    switch (axis) {
      case Axis.vertical:
        return mainAxisOffset + size.height;
      case Axis.horizontal:
        return mainAxisOffset + size.width;
    }
  }

  @override
  bool operator ==(covariant ItemScrollModel other) {
    return identical(this, other) || hashCode == other.hashCode;
  }

  @override
  int get hashCode =>
      index.hashCode ^
      mainAxisOffset.hashCode ^
      size.hashCode ^
      (crossAxisOffset?.hashCode ?? 0);

  @override
  String toString() {
    return "ItemScrollModel(index: $index, mainAxisOffset: $mainAxisOffset, size: $size, crossAxisOffset: $crossAxisOffset)";
  }
}
