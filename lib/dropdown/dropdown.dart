import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void _ensureLegallyInvokeVoidCallback(Function callback) {
  if (WidgetsBinding.instance.schedulerPhase ==
      SchedulerPhase.postFrameCallbacks) {
    callback();
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }
}

typedef DropdownItemLoader<T> = FutureOr<List<T>> Function();
typedef DropdownItemSearcher<T> = FutureOr<List<T>> Function(String);
typedef MenuItemBuilder<T> = Widget Function(BuildContext, T);
typedef DropdownButtonBuilder<T> = Widget Function(BuildContext, T?);
typedef AnimationMenuBuilder = Widget Function(
  BuildContext,
  Animation<double>,
  Widget? child,
);

/// todo: undo search results
abstract mixin class _DropdownItemManager<T> {
  T? _selected;
  T? get selectedItem => _selected;

  List<T> _items = [];

  List<T>? _itemsBeforeSearch;

  List<T> get items => List.unmodifiable(_items);

  Future<void> loadMore(DropdownItemLoader<T> loader) async {
    await _load(loader);
  }

  Future<void> search(DropdownItemSearcher<T> searcher, String query) async {
    _itemsBeforeSearch ??= List.unmodifiable(_items);

    await _load(() => searcher(query), merge: false);
  }

  void restore() {
    if (_itemsBeforeSearch != null) {
      _items = List.from(_itemsBeforeSearch!);
      _itemsBeforeSearch = null;
      _rebuildMenu();
    }
  }

  bool _loading = false;

  Future<void> _load(DropdownItemLoader<T> loader, {bool merge = true}) async {
    if (!merge) {
      _loading = true;
      _rebuildMenu();
    }

    try {
      final items = await loader();

      if (merge) {
        _items = [
          ..._items,
          ...items,
        ];
      } else {
        _items = items;
      }
    } catch (e) {
      print(e);
    } finally {
      _loading = false;
      _rebuildMenu();
    }
  }

  void _rebuildMenu();
}

class DropdownController<T> extends ChangeNotifier
    with _DropdownItemManager<T> {
  final LayerLink _link = LayerLink();

  LayerLink get link => _link;

  DropdownController({T? selected, List<T>? items})
      : assert(
          () {
            final existed = items?.any(
                    (element) => element == selected || selected == null) ??
                false;
            return existed;
          }(),
          "The initial selected item must be in the items list.",
        ) {
    _selected = selected;

    if (items != null) {
      _items.addAll(items);
    }
  }

  /// Whether the dropdown menu is displaying.
  bool get isOpen => _overlay != null;

  OverlayEntry? _overlay;

  /// Opens the dropdown menu.
  void open() {
    if (_overlay != null || _state == null) return;
    print("opened");

    _overlay = _state!._buildOverlay();

    Overlay.of(_state!.context).insert(_overlay!);
  }

  /// Dismisses the dropdown menu.
  void dismiss() {
    if (_overlay != null) {
      _overlay?.remove();
      _overlay = null;
      print("dismissed");
    }
  }

  /// Selects the given value and dismisses the dropdown menu.
  /// Typically, developers should programmatically call this method to select a value,
  /// e.g., wrapping a list item with a [GestureDetector] and calling this method in its [onTap] callback.
  void select(
    T value, {
    bool dismiss = true,
    bool notify = true,
  }) {
    if (_selected != value) {
      _selected = value;
      if (notify) {
        notifyListeners();
      }
    }

    if (dismiss) {
      this.dismiss();
    }
  }

  _DropdownState? _state;
  void _attach(_DropdownState state) {
    assert(_state == null,
        "The dropdown controller can only be attached with one [Dropdown] widget.");

    if (_state != state) {
      dismiss();
    }

    _state = state;
  }

  void _detach() {
    dismiss();
    _state = null;
  }

  @override
  void _rebuildMenu() {
    _ensureLegallyInvokeVoidCallback(() {
      if (_overlay != null) {
        _overlay!.markNeedsBuild();
      }
    });
  }

  @override
  void dispose() {
    _overlay?.dispose();
    _overlay = null;
    super.dispose();
  }
}

/// todo: support animating the dropdown menu
class Dropdown<T> extends StatefulWidget {
  /// The widget that will be used to trigger the dropdown.
  /// It can be a button, a text field, or any other widget.
  final DropdownButtonBuilder<T> builder;
  // final AnimationMenuBuilder? animationBuilder;
  // final Duration duration;

  /// The controller that will be used to manage the dropdown menu and items.
  final DropdownController<T> controller;

  /// the anchor point of the dropdown menu should be aligned to the dropdown trigger widget.
  final Alignment targetAnchor;

  /// the anchor point of the dropdown menu should use to align itself with the target anchor.
  final Alignment anchor;

  /// the offset between the dropdown trigger and the dropdown menu after aligning them.
  final Offset offset;

  /// The builder that will be used to build the menu items.
  final MenuItemBuilder<T> itemBuilder;

  /// The builder that will be used to build the separator between the menu items.
  /// If it's null, the menu will use [ListView.builder]; otherwise, it will use [ListView.separated]
  final IndexedWidgetBuilder? separatorBuilder;

  /// todo: better loading indicator
  /// The builder that will be used to build the loading indicator
  /// when the dropdown is loading more items via [DropdownController.search]
  final WidgetBuilder? loadingBuilder;

  /// The decoration that will be used to decorate the dropdown menu.
  /// It only takes effect when the menu is displaying.
  final BoxDecoration? menuDecoration;

  /// The constraints that will be used to constrain the dropdown menu.
  /// It only takes effect when the menu is displaying.
  final BoxConstraints? menuConstraints;

  /// todo: support different axis
  /// Whether the dropdown menu should be constrained by the cross axis of the dropdown trigger.
  /// It will work with [menuConstraints] to constrain the dropdown menu if applicable.
  /// It only takes effect when the menu is displaying.
  final bool crossAxisConstrained;

  /// Whether the dropdown menu should be dismissed when the user taps outside of it.
  final bool dismissible;

  final bool enabled;

  const Dropdown({
    super.key,
    required this.builder,
    required this.controller,
    required this.itemBuilder,
    this.separatorBuilder,
    this.loadingBuilder,
    this.menuConstraints,
    this.menuDecoration,
    this.targetAnchor = Alignment.bottomLeft,
    this.anchor = Alignment.topLeft,
    this.offset = Offset.zero,
    this.crossAxisConstrained = true,
    this.dismissible = true,
    this.enabled = true,
  });

  @override
  State<Dropdown<T>> createState() => _DropdownState<T>();
}

class _DropdownState<T> extends State<Dropdown<T>> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant Dropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach();
      widget.controller._attach(this);
    }

    if (oldWidget.itemBuilder != widget.itemBuilder ||
        oldWidget.separatorBuilder != widget.separatorBuilder ||
        oldWidget.menuDecoration != widget.menuDecoration ||
        oldWidget.menuConstraints != widget.menuConstraints ||
        oldWidget.targetAnchor != widget.targetAnchor ||
        oldWidget.anchor != widget.anchor ||
        oldWidget.offset != widget.offset ||
        oldWidget.crossAxisConstrained != widget.crossAxisConstrained ||
        oldWidget.loadingBuilder != widget.loadingBuilder) {
      widget.controller._rebuildMenu();
    }
  }

  @override
  void dispose() {
    widget.controller._detach();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) {
        return TapRegion(
          onTapOutside: (event) {
            if (widget.dismissible && !_contain(event.position)) {
              widget.controller.dismiss();
            }
          },
          child: _DropdownMenu<T>(
            link: widget.controller._link,
            loading: widget.controller._loading,
            items: widget.controller.items,
            itemBuilder: widget.itemBuilder,
            separatorBuilder: widget.separatorBuilder,
            loadingBuilder: widget.loadingBuilder,
            decoration: widget.menuDecoration,
            constraints: widget.menuConstraints,
            targetAnchor: widget.targetAnchor,
            anchor: widget.anchor,
            offset: widget.offset,
            crossAxisConstrained: widget.crossAxisConstrained,
          ),
        );
      },
    );
  }

  bool _contain(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);
    return renderBox.paintBounds.contains(localPosition);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: widget.controller._link,
      child: TapRegion(
        onTapInside: widget.enabled
            ? (_) {
                if (widget.controller.isOpen) {
                  widget.controller.dismiss();
                } else {
                  widget.controller.open();
                }
              }
            : null,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (inner, child) =>
              widget.builder(context, widget.controller.selectedItem),
        ),
      ),
    );
  }
}

/// [CompositedTransformFollower.showWhenUnlinked] Only takes effects after the [CompositedTransformTarget]'s render is disposed
class _DropdownMenu<T> extends StatelessWidget {
  final LayerLink link;
  final Alignment targetAnchor;
  final Alignment anchor;
  final Offset offset;
  final List<T> items;
  final MenuItemBuilder<T> itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final BoxDecoration? decoration;
  final BoxConstraints? constraints;
  final bool crossAxisConstrained;
  final TapRegionCallback? onTapOutside;

  final AnimationMenuBuilder? animationBuilder;
  final Animation<double>? animation;

  final WidgetBuilder? loadingBuilder;
  final bool loading;
  final T? selected;
  const _DropdownMenu({
    super.key,
    required this.link,
    required this.items,
    required this.itemBuilder,
    this.separatorBuilder,
    this.decoration,
    this.constraints,
    this.selected,
    this.targetAnchor = Alignment.bottomLeft,
    this.anchor = Alignment.topLeft,
    this.offset = Offset.zero,
    this.crossAxisConstrained = true,
    this.onTapOutside,
    this.animationBuilder,
    this.animation,
    this.loadingBuilder,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final reversed = anchor.y > 0;

    Widget result;

    if (loading) {
      result = loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    } else {
      result = separatorBuilder != null
          ? ListView.separated(
              reverse: reversed,
              itemBuilder: (inner, index) => itemBuilder(context, items[index]),
              separatorBuilder: separatorBuilder!,
              itemCount: items.length,
            )
          : ListView.builder(
              reverse: reversed,
              itemCount: items.length,
              itemBuilder: (inner, index) => itemBuilder(context, items[index]),
            );
    }

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

    if (animationBuilder != null && animation != null) {
      result = animationBuilder!(context, animation!, result);
    }

    return Align(
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        targetAnchor: targetAnchor,
        followerAnchor: anchor,
        offset: offset,
        child: Material(
          type: MaterialType.card,
          child: DecoratedBox(
            decoration: decoration ?? const BoxDecoration(),
            child: result,
          ),
        ),
      ),
    );
  }
}
