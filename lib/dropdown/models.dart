import 'dart:async';

import 'package:flutter/widgets.dart';

class DropdownMenuPosition {
  /// the anchor point of the dropdown menu should be aligned to the dropdown trigger widget.
  final Alignment targetAnchor;

  /// the anchor point of the dropdown menu should use to align itself with the target anchor.
  final Alignment anchor;

  /// the offset between the dropdown trigger and the dropdown menu after aligning them.
  final Offset offset;

  const DropdownMenuPosition({
    this.targetAnchor = Alignment.bottomLeft,
    this.anchor = Alignment.topLeft,
    this.offset = Offset.zero,
  });

  DropdownMenuPosition copyWith({
    Alignment? targetAnchor,
    Alignment? anchor,
    Offset? offset,
  }) {
    return DropdownMenuPosition(
      targetAnchor: targetAnchor ?? this.targetAnchor,
      anchor: anchor ?? this.anchor,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DropdownMenuPosition &&
        other.targetAnchor == targetAnchor &&
        other.anchor == anchor &&
        other.offset == offset;
  }

  @override
  int get hashCode => targetAnchor.hashCode ^ anchor.hashCode ^ offset.hashCode;
}

typedef DropdownItemLoader<T> = FutureOr<List<T>> Function();
typedef DropdownItemAsyncSearcher<T> = Future<List<T>> Function(String);
typedef DropdownItemMatcher<T> = bool Function(T, String);
typedef MenuItemBuilder<T> = Widget Function(BuildContext, T);
typedef DropdownButtonBuilder<T> = Widget Function(BuildContext, T?);
typedef AnimationMenuBuilder = Widget Function(
  BuildContext,
  Animation<double>,
  Widget? child,
);

typedef DropdownMenuBuilder<T> = Widget Function(
    BuildContext, List<T> items, bool loading);
