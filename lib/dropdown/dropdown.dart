import 'dart:async';

import 'package:flutter/material.dart' hide DropdownButtonBuilder;
import 'package:flutter/scheduler.dart';
import 'package:flutter_tips/dropdown/delegate.dart';
import 'package:flutter_tips/dropdown/models.dart';

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

/// todo: undo search results
abstract mixin class _DropdownItemManager<T> {
  T? _selected;
  T? get selectedItem => _selected;

  List<T> _items = [];

  List<T>? _itemsBeforeSearch;

  List<T> get items => List.unmodifiable(_items);

  void addItems(List<T> items, {bool append = true}) {
    if (!append) {
      _items = _mergeItems(items);
    } else {
      _items = [
        ..._items,
        ...items,
      ];
    }
    _rebuildMenu();
  }

  void replaceItems(List<T> items) {
    _itemsBeforeSearch ??= List.unmodifiable(_items);
    _items = items;
    _rebuildMenu();
  }

  bool _loading = false;

  Future<void> loadMore(
    DropdownItemLoader<T> loader, {
    bool appendOnly = true,
  }) async {
    markAsLoading();

    try {
      final items = await loader();

      if (appendOnly) {
        _items = [
          ..._items,
          ...items,
        ];
      } else {
        _items = _mergeItems(items);
      }
    } catch (e) {
      print(e);
    } finally {
      markAsLoaded();
      _rebuildMenu();
    }
  }

  void markAsLoading() {
    if (!_loading) {
      _loading = true;
      _rebuildMenu();
    }
  }

  void markAsLoaded() {
    if (_loading) {
      _loading = false;
      _rebuildMenu();
    }
  }

  void search(DropdownItemMatcher<T> matcher, String query) {
    _itemsBeforeSearch ??= List.unmodifiable(_items);
    _items = _itemsBeforeSearch!
        .where((element) => matcher(element, query))
        .toList();
    _rebuildMenu();
  }

  void restore() {
    _loading = false;
    if (_itemsBeforeSearch != null) {
      _items = List.from(_itemsBeforeSearch!);
      _itemsBeforeSearch = null;
    }

    _rebuildMenu();
  }

  List<T> _mergeItems(List<T> items) {
    final Set<T> s = Set.from(_items);
    s.addAll(items);
    return s.toList();
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
            final valid = selected == null ||
                (items?.any((element) => element == selected) ?? true);
            return valid;
          }(),
          "The initial selected item must be in the items list, or null.",
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
    T? value, {
    bool dismiss = true,
    bool notify = true,
  }) {
    assert(
      value == null || _items.any((element) => element == value),
      "The selected item must be in the items list, or null.",
    );

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
    // assert(_state == null,
    //     "The dropdown controller can only be attached with one [Dropdown] widget.");

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

  final DropdownMenuBuilderDelegate<T> delegate;

  /// The decoration that will be used to decorate the dropdown menu.
  /// It only takes effect when the menu is displaying.
  final BoxDecoration? menuDecoration;

  /// The constraints that will be used to constrain the dropdown menu.
  /// It only takes effect when the menu is displaying.
  final BoxConstraints? menuConstraints;

  /// The position that will be used to position the dropdown menu.
  final DropdownMenuPosition menuPosition;

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
    required this.controller,
    required this.builder,
    required this.delegate,
    this.menuConstraints,
    this.menuDecoration,
    this.menuPosition = const DropdownMenuPosition(),
    this.crossAxisConstrained = true,
    this.dismissible = true,
    this.enabled = true,
  });

  Dropdown.list({
    super.key,
    required this.builder,
    required this.controller,
    this.menuConstraints,
    this.menuDecoration,
    this.menuPosition = const DropdownMenuPosition(),
    this.crossAxisConstrained = true,
    this.dismissible = true,
    this.enabled = true,
    required MenuItemBuilder<T> itemBuilder,
    IndexedWidgetBuilder? separatorBuilder,
    WidgetBuilder? loadingBuilder,
    WidgetBuilder? emptyListBuilder,
  }) : delegate = ListViewMenuBuilderDelegate<T>(
          items: controller.items,
          itemBuilder: itemBuilder,
          position: menuPosition,
          separatorBuilder: separatorBuilder,
          loadingBuilder: loadingBuilder,
          emptyListBuilder: emptyListBuilder,
        );

  Dropdown.custom({
    super.key,
    required this.builder,
    required this.controller,
    required DropdownMenuBuilder<T> menuBuilder,
    this.menuConstraints,
    this.menuDecoration,
    this.menuPosition = const DropdownMenuPosition(),
    this.crossAxisConstrained = true,
    this.dismissible = true,
    this.enabled = true,
  }) : delegate = CustomMenuBuilderDelegate<T>(menuBuilder);

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

    if (oldWidget.menuDecoration != widget.menuDecoration ||
        oldWidget.menuConstraints != widget.menuConstraints ||
        oldWidget.menuPosition != widget.menuPosition ||
        oldWidget.crossAxisConstrained != widget.crossAxisConstrained ||
        oldWidget.dismissible != widget.dismissible ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.delegate != widget.delegate) {
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
          child: OverlayedDropdownMenu<T>(
            link: widget.controller._link,
            loading: widget.controller._loading,
            items: widget.controller.items,
            delegate: widget.delegate,
            decoration: widget.menuDecoration,
            constraints: widget.menuConstraints,
            position: widget.menuPosition,
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
