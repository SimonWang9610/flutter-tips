import 'dart:math';
import 'package:flutter/material.dart';
import 'button_flow_delegate.dart';

/// [radian] represents the radian between the second entry and the last entry, starting from [startRad]
/// the first entry is always the main entry, so we flow entries from the second to the last ones
/// therefore, the second entry is always put at [startRad], while the last one is always put at [startRad] + [radian]
class CircularFlowDelegate extends ButtonFlowDelegate {
  double? perRad;

  final double radian;
  final double startRad;
  final double radius;

  CircularFlowDelegate({
    required super.animation,
    required this.radian,
    required this.radius,
    required this.startRad,
    super.alignment = Alignment.center,
  });

  @override
  void paintChildren(FlowPaintingContext context) {
    calculatePerRad(context.childCount);
    super.paintChildren(context);
  }

  Size mainEntrySize = Size.zero;

  /// we should ensure the distance between each child and the main entry is [radius]:
  ///   therefore the effective radius should be [radius] + [mainEntrySize]
  /// and each child may not be a regular square/circle
  /// so we calculate [dx]/[dy] separately
  @override
  Offset calculateOffset(Size childSize, int index) {
    assert(perRad != null, 'have no [perRad] for each child');

    if (index == 0) {
      mainEntrySize = childSize;
      return Offset.zero;
    }

    final effectiveAngle = startRad + (index - 1) * perRad!;

    final dx = (radius + mainEntrySize.width / 2) *
        cos(effectiveAngle) *
        animation.value;
    final dy = (radius + mainEntrySize.height / 2) *
        sin(effectiveAngle) *
        animation.value;

    return Offset(dx, dy);
  }

  @override
  Matrix4 transform(Offset relativeOffset, Offset origin) {
    return Matrix4.translationValues(
      origin.dx + relativeOffset.dx,
      origin.dy + relativeOffset.dy,
      0,
    );
  }

  /// the main entry should not be counted
  void calculatePerRad(int count) {
    final divisor = max(1, count - 2);

    perRad ??= radian / divisor;
    print("divisor: $divisor, perRad: $perRad");
  }
}
