import 'package:flutter/material.dart';
import 'models.dart';

class _MatchPair<T> {
  final Object key;
  final List<T> items;

  _MatchPair(this.key, this.items);
}

mixin class _ItemSearchHistoryBucket<T> {
  final Map<Object, _MatchPair<T>> _history = {};
  final List<Object> _order = [];

  void _addHistory(Object key, List<T> items) {
    if (_history.containsKey(key)) {
      _order.remove(key);
    }
    _order.add(key);
    _history[key] = _MatchPair(key, items);
  }

  _MatchPair<T>? _removeHistory(Object? key) {
    if (key == null) {
      return null;
    }
    final pair = _history.remove(key);

    if (pair != null) {
      _order.remove(key);
    }

    return pair;
  }

  void _clearHistory() {
    _history.clear();
    _order.clear();
  }

  void _popHistory() {
    if (_order.isNotEmpty) {
      final key = _order.removeLast();
      _history.remove(key);
    }
  }

  _MatchPair<T>? get _currentHistory =>
      _order.isNotEmpty ? _history[_order.last] : null;
}

abstract mixin class _MenuStatusNotifier {
  bool _loading = false;
  bool get loading => _loading;

  void markAsLoading() {
    if (!_loading) {
      _loading = true;
      rebuildMenu();
    }
  }

  void markAsLoaded() {
    if (_loading) {
      _loading = false;
      rebuildMenu();
    }
  }

  void rebuildMenu();
}

abstract base class DropdownItemManager<T>
    with _ItemSearchHistoryBucket<T>, _MenuStatusNotifier {
  /// Set the given items to the dropdown menu.
  /// if [replace], the current items will be replaced with the given items, and all history will be cleared.
  /// if [rebuild], the menu will be rebuilt after the items are set.
  ///
  /// For[MultiSelectionDropdownController]
  ///   if [replace] is true, the previous selected items will be cleared and the new items will be set as selected.
  ///   if [replace] is false, the new items's selected status will be ignored.
  ///
  /// For[SingleSelectionDropdownController]
  ///   if [replace] is true, the previous selected item will be cleared and the new item will be set as selected.
  ///   if [replace] is false, the new item's selected status will be ignored.
  void setItems(
    List<DropdownItem<T>> items, {
    bool replace = false,
    bool rebuild = true,
  }) {
    if (!replace) {
      _itemValues.addAll(items.map((e) => e.value));
    } else {
      _clearHistory();
      _itemValues = items.map((e) => e.value).toSet();
    }

    if (rebuild) {
      rebuildMenu();
    }
  }

  /// Set the given items to the dropdown menu as history items, it would be the top items in the history.
  /// if [rebuild], the menu will be rebuilt after the items are set.
  void setAsHistoryItems(Object key, List<DropdownItem<T>> items,
      {bool rebuild = false}) {
    _addHistory(key, items.map((e) => e.value).toList());

    if (rebuild) {
      rebuildMenu();
    }
  }

  /// Search the items that match the given query, and set the matched items to the dropdown menu.
  /// It would be marked as a history and not modify the original items.
  void search<K extends Object>(
    K query, {
    required DropdownItemMatcher<K, T> matcher,
  }) {
    if (_currentHistory?.key == query) {
      return;
    }

    final old = _removeHistory(query);

    if (old != null) {
      _addHistory(query, old.items);
    } else {
      final matchedItems =
          _itemValues.where((item) => matcher(query, item)).toList();

      _addHistory(query, matchedItems);
    }

    rebuildMenu();
  }

  /// Load the items from the given loader, and set the items to the dropdown menu.
  /// The loaded items would replace the current items if [replace] is true;
  /// otherwise, the loaded items would be merged with the current items.
  /// if [onException] is provided, it would be called when an exception is thrown during the loading.
  Future<void> load(
    DropdownItemLoader<T> loader, {
    bool replace = false,
    bool Function(Object)? onException,
  }) async {
    _clearHistory();
    markAsLoading();

    bool shouldMarkAsLoaded = true;

    try {
      final items = await loader();
      setItems(items, replace: replace, rebuild: false);
    } catch (e) {
      shouldMarkAsLoaded = onException?.call(e) ?? true;
    } finally {
      if (shouldMarkAsLoaded) {
        markAsLoaded();
      }
    }
  }

  /// Restore the items to the previous state.
  /// if [onlyOnce], it would try to pop the history once to show the previous history result;
  /// otherwise, it would clear all history and show the original items.
  void restore({bool onlyOnce = false}) {
    if (onlyOnce) {
      _popHistory();
    } else {
      _clearHistory();
    }

    rebuildMenu();
  }

  /// original items
  Set<T> _itemValues = {};

  /// The current items that will be shown in the dropdown menu.
  List<T> get _currentItemValues =>
      _currentHistory?.items ?? _itemValues.toList();
}

mixin DropdownOverlayBuilderDelegate<W extends StatefulWidget> on State<W> {
  OverlayEntry buildMenuOverlay();
}

abstract base class DropdownController<T> extends DropdownItemManager<T>
    with ChangeNotifier {
  final bool _unselectable;
  DropdownController(this._unselectable);

  factory DropdownController.single({
    bool? unselectable,
    List<DropdownItem<T>>? items,
  }) = SingleSelectionDropdownController;

  factory DropdownController.multi({
    bool? unselectable,
    List<DropdownItem<T>>? items,
  }) = MultiSelectionDropdownController;

  bool get isOpen => _menuOverlay != null;
  OverlayEntry? _menuOverlay;

  /// Open the dropdown menu.
  /// if [onOpened] is provided, it would be called after the menu is opened.
  void open({VoidCallback? onOpened}) {
    if (isOpen || _currentAttachedState == null) return;

    _menuOverlay = _currentAttachedState!.buildMenuOverlay();
    Overlay.of(_currentAttachedState!.context).insert(_menuOverlay!);
    onOpened?.call();
  }

  /// Dismiss the dropdown menu.
  /// if [onDismissed] is provided, it would be called after the menu is dismissed.
  void dismiss({VoidCallback? onDismissed}) {
    if (!isOpen) return;
    _menuOverlay?.remove();
    _menuOverlay = null;
    onDismissed?.call();
  }

  /// Select the given value.
  /// if [dismiss], the menu will be dismissed no matter the value is selected or not.
  /// if [refresh], the menu will be rebuilt after the value is selected.
  ///
  /// if [value] is null or duplicated, it may unselect it if [_unselectable] is true.
  void select(
    T? value, {
    bool dismiss = true,
    bool refresh = true,
  });

  /// Current items that will be shown in the dropdown menu, see also [_currentItemValues].
  List<DropdownItem<T>> get currentItems;

  /// The last selected item,
  /// for [SingleSelectionDropdownController], it would be the current selected item;
  /// for [MultiSelectionDropdownController], it would be the last selected item.
  DropdownItem<T>? getLastSelected();

  /// All selected items,
  /// for [SingleSelectionDropdownController], it would be the current selected item;
  /// for [MultiSelectionDropdownController], it would be all selected items.
  List<DropdownItem<T>> getAllSelectedItems();

  DropdownOverlayBuilderDelegate? get _currentAttachedState =>
      _attachedStates.isNotEmpty ? _attachedStates.last : null;

  final List<DropdownOverlayBuilderDelegate> _attachedStates = [];

  void attach(DropdownOverlayBuilderDelegate state) {
    if (_currentAttachedState != state) {
      dismiss();
    }

    if (!_attachedStates.contains(state)) {
      _attachedStates.add(state);
    }
  }

  void detach() {
    dismiss();
    if (_attachedStates.isNotEmpty) {
      _attachedStates.removeLast();
    }
  }

  @override
  void rebuildMenu() {
    // if (WidgetsBinding.instance.schedulerPhase ==
    //     SchedulerPhase.postFrameCallbacks) {
    // } else {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _menuOverlay?.markNeedsBuild();
    //   });
    // }
    _menuOverlay?.markNeedsBuild();
  }

  @override
  void dispose() {
    _menuOverlay?.dispose();
    _menuOverlay = null;
    _attachedStates.clear();
    super.dispose();
  }
}

final class MultiSelectionDropdownController<T> extends DropdownController<T> {
  MultiSelectionDropdownController({
    bool? unselectable,
    List<DropdownItem<T>>? items,
  }) : super(unselectable ?? false) {
    if (items != null) {
      for (final item in items) {
        if (item.selected) {
          _selectedItems.add(item.value);
        }
        _itemValues.add(item.value);
      }
    }
  }

  final Set<T> _selectedItems = {};

  @override
  List<DropdownItem<T>> get currentItems => _currentItemValues
      .map((e) => DropdownItem(
            value: e,
            selected: _selectedItems.contains(e),
          ))
      .toList();

  @override
  DropdownItem<T>? getLastSelected() => _selectedItems.isNotEmpty
      ? DropdownItem(value: _selectedItems.last, selected: true)
      : null;

  @override
  List<DropdownItem<T>> getAllSelectedItems() => _selectedItems
      .map((e) => DropdownItem(value: e, selected: true))
      .toList();

  @override
  void setItems(
    List<DropdownItem<T>> items, {
    bool replace = false,
    bool rebuild = true,
  }) {
    if (replace) {
      _selectedItems.clear();
      for (final item in items) {
        if (item.selected) {
          _selectedItems.add(item.value);
        }
      }
    }

    super.setItems(items, replace: replace, rebuild: rebuild);
  }

  @override
  void select(
    T? value, {
    bool dismiss = true,
    bool refresh = true,
  }) {
    if (dismiss) {
      this.dismiss();
    }

    final selected = _selectedItems.contains(value);

    if (selected) {
      if (_unselectable) {
        _selectedItems.remove(value);
      }
    } else if (value != null) {
      _selectedItems.add(value);
    }

    if (refresh) {
      notifyListeners();
      rebuildMenu();
    }
  }

  @override
  void dispose() {
    _selectedItems.clear();
    super.dispose();
  }
}

final class SingleSelectionDropdownController<T> extends DropdownController<T> {
  SingleSelectionDropdownController({
    bool? unselectable,
    List<DropdownItem<T>>? items,
  }) : super(unselectable ?? false) {
    if (items != null) {
      for (final item in items) {
        if (item.selected) {
          assert(_selectedItemValue == null,
              "Only one item can be selected at a time");
          _selectedItemValue = item.value;
        }
        _itemValues.add(item.value);
      }
    }
  }

  T? _selectedItemValue;

  DropdownItem<T>? get selectedItem => _selectedItemValue != null
      ? DropdownItem(value: _selectedItemValue as T, selected: true)
      : null;

  @override
  List<DropdownItem<T>> get currentItems => _currentItemValues
      .map((e) => DropdownItem(
            value: e,
            selected: e == _selectedItemValue,
          ))
      .toList();

  @override
  DropdownItem<T>? getLastSelected() => _selectedItemValue != null
      ? DropdownItem(value: _selectedItemValue as T, selected: true)
      : null;

  @override
  List<DropdownItem<T>> getAllSelectedItems() => _selectedItemValue != null
      ? [DropdownItem(value: _selectedItemValue as T, selected: true)]
      : [];

  @override
  void setItems(
    List<DropdownItem<T>> items, {
    bool replace = false,
    bool rebuild = true,
  }) {
    if (replace) {
      _selectedItemValue = null;

      for (final item in items) {
        if (item.selected) {
          assert(_selectedItemValue == null,
              "Only one item can be selected at a time");
          _selectedItemValue = item.value;
        }
      }
    }

    super.setItems(items, replace: replace, rebuild: rebuild);
  }

  @override
  void select(
    T? value, {
    bool dismiss = true,
    bool refresh = true,
  }) {
    if (dismiss) {
      this.dismiss();
    }

    if (value == null || value == _selectedItemValue) {
      if (_unselectable) {
        _selectedItemValue = null;
      }
    } else {
      _selectedItemValue = value;
    }

    if (refresh) {
      notifyListeners();
      rebuildMenu();
    }
  }

  @override
  void dispose() {
    _selectedItemValue = null;
    super.dispose();
  }
}
