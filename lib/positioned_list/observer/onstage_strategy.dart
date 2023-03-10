import 'package:flutter/foundation.dart';

bool _outside(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
}) {
  return trailingOffset <= leadingEdge || leadingOffset >= trailingEdge;
}

bool _inside(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
}) {
  return leadingOffset >= leadingEdge && trailingOffset <= trailingEdge;
}

bool _contain(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
}) =>
    leadingOffset < leadingEdge && trailingOffset > trailingEdge;

bool _tolerate(
  double leadingOffset,
  double trailingOffset, {
  required double leadingEdge,
  required double trailingEdge,
  required double maxScrollExtent,
  double tolerance = 0.3,
}) {
  if (_outside(leadingOffset, trailingOffset,
      leadingEdge: leadingEdge, trailingEdge: trailingEdge)) {
    return false;
  } else if (_inside(leadingOffset, trailingOffset,
      leadingEdge: leadingEdge, trailingEdge: trailingEdge)) {
    return true;
  } else if (_contain(leadingOffset, trailingOffset,
      leadingEdge: leadingEdge, trailingEdge: trailingEdge)) {
    return (trailingEdge - leadingEdge) / (trailingOffset - leadingOffset) >
        tolerance;
  } else {
    final total = trailingOffset - leadingOffset;

    final part = leadingOffset < leadingEdge
        ? trailingOffset - leadingEdge
        : trailingEdge - leadingOffset;
    return part / total > tolerance;
  }
}

enum PredicatorStrategy {
  inside,
  tolerance,
}

class OnstagePredicator {
  static bool predict(
    double leadingOffset,
    double trailingOffset, {
    required double leadingEdge,
    required double trailingEdge,
    required double maxScrollExtent,
    double tolerance = 0.5,
    PredicatorStrategy strategy = PredicatorStrategy.tolerance,
  }) {
    print(
        "leading: $leadingOffset, trailing: $trailingOffset, min: $leadingEdge, max: $trailingEdge");
    switch (strategy) {
      case PredicatorStrategy.tolerance:
        return _tolerate(
          leadingOffset,
          trailingOffset,
          leadingEdge: leadingEdge,
          trailingEdge: trailingEdge,
          tolerance: clampDouble(tolerance, 0, 1.0),
          maxScrollExtent: maxScrollExtent,
        );
      case PredicatorStrategy.inside:
        return _inside(
          leadingOffset,
          trailingOffset,
          leadingEdge: leadingEdge,
          trailingEdge: trailingEdge,
        );
    }
  }
}
