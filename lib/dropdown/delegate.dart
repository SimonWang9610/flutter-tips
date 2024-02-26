import 'package:flutter/material.dart';
import 'package:flutter_tips/dropdown/models.dart';

abstract base class DropdownMenuBuilderDelegate<T> {
  const DropdownMenuBuilderDelegate();
  Widget build(BuildContext context, List<T> items, bool loading);
}

final class CustomMenuBuilderDelegate<T>
    extends DropdownMenuBuilderDelegate<T> {
  final DropdownMenuBuilder<T> builder;

  const CustomMenuBuilderDelegate(this.builder);

  @override
  Widget build(BuildContext context, List<T> items, bool loading) {
    return builder(context, items, loading);
  }

  @override
  bool operator ==(covariant CustomMenuBuilderDelegate<T> other) {
    if (identical(this, other)) return true;

    return other.builder == builder;
  }

  @override
  int get hashCode => builder.hashCode;
}

final class ListViewMenuBuilderDelegate<T>
    extends DropdownMenuBuilderDelegate<T> {
  final List<T> items;
  final MenuItemBuilder<T> itemBuilder;
  final DropdownMenuPosition position;
  final IndexedWidgetBuilder? separatorBuilder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyListBuilder;

  const ListViewMenuBuilderDelegate({
    required this.items,
    required this.itemBuilder,
    required this.position,
    this.separatorBuilder,
    this.loadingBuilder,
    this.emptyListBuilder,
  });

  @override
  Widget build(BuildContext context, List<T> items, bool loading) {
    final reversed = position.anchor.y > 0;

    Widget result;

    if (loading) {
      result = loadingBuilder?.call(context) ??
          const Center(
            child: CircularProgressIndicator(),
          );
    } else if (items.isEmpty) {
      result = emptyListBuilder?.call(context) ??
          const Center(
            child: Text("No items"),
          );
    } else {
      result = separatorBuilder != null
          ? ListView.separated(
              reverse: reversed,
              padding: EdgeInsets.zero,
              itemBuilder: (inner, index) => itemBuilder(context, items[index]),
              separatorBuilder: separatorBuilder!,
              itemCount: items.length,
            )
          : ListView.builder(
              reverse: reversed,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (inner, index) => itemBuilder(context, items[index]),
            );
    }

    return result;
  }

  @override
  bool operator ==(covariant ListViewMenuBuilderDelegate<T> other) {
    if (identical(this, other)) return true;

    return other.items == items &&
        other.itemBuilder == itemBuilder &&
        other.position == position &&
        other.separatorBuilder == separatorBuilder &&
        other.loadingBuilder == loadingBuilder &&
        other.emptyListBuilder == emptyListBuilder;
  }

  @override
  int get hashCode {
    return items.hashCode ^
        itemBuilder.hashCode ^
        position.hashCode ^
        separatorBuilder.hashCode ^
        loadingBuilder.hashCode ^
        emptyListBuilder.hashCode;
  }
}

class OverlayedDropdownMenu<T> extends StatelessWidget {
  final LayerLink link;

  /// The position that will be used to position the dropdown menu.
  final DropdownMenuPosition position;
  final BoxConstraints? constraints;
  final BoxDecoration? decoration;
  final List<T> items;
  final DropdownMenuBuilderDelegate<T> delegate;

  final bool crossAxisConstrained;
  final bool useMaterial;

  final bool loading;

  const OverlayedDropdownMenu({
    super.key,
    required this.link,
    required this.position,
    required this.items,
    required this.delegate,
    this.constraints,
    this.decoration,
    this.crossAxisConstrained = true,
    this.useMaterial = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = delegate.build(context, items, loading);

    final effectiveConstraints = crossAxisConstrained
        ? constraints?.enforce(
            BoxConstraints.tightFor(width: link.leaderSize?.width),
          )
        : constraints;

    if (effectiveConstraints != null) {
      result = ConstrainedBox(
        constraints: effectiveConstraints,
        child: result,
      );
    } else if (crossAxisConstrained) {
      result = SizedBox(
        width: link.leaderSize?.width,
        child: result,
      );
    }

    if (decoration != null) {
      result = DecoratedBox(
        decoration: decoration!,
        child: result,
      );
    }

    if (useMaterial) {
      result = Material(
        child: result,
      );
    }

    return Align(
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        targetAnchor: position.targetAnchor,
        followerAnchor: position.anchor,
        offset: position.offset,
        child: result,
      ),
    );
  }
}
