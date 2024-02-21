import 'package:flutter/material.dart';
import 'package:flutter_tips/onscreen/background.dart';
import 'package:flutter_tips/onscreen/widget.dart';

class OnscreenController extends ChangeNotifier {
  final Map<OnscreenPosition, OnscreenElement> _elements;

  OnscreenController({
    Map<OnscreenPosition, OnscreenElement>? elements,
    OnscreenPosition? initialFocus,
  })  : _elements = elements ?? {},
        _focusedPosition = initialFocus;

  OnscreenElement? get focusedElement =>
      focusedPosition != null ? _elements[focusedPosition!] : null;

  OnscreenPosition? _focusedPosition;
  OnscreenPosition? get focusedPosition => _focusedPosition;

  bool get hasFocus => _focusedPosition != null;

  void focus(OnscreenPosition position) {
    if (_focusedPosition != position) {
      _focusedPosition = position;
      notifyListeners();
    }
  }

  void unfocus() {
    if (_focusedPosition != null) {
      _focusedPosition = null;
      notifyListeners();
    }
  }

  OnscreenElement? getElement(OnscreenPosition position) {
    return _elements[position];
  }

  void update(OnscreenPosition position, OnscreenElement element) {
    _elements[position] = element;

    if (_focusedPosition == position) {
      notifyListeners();
    }

    _refresher?.refresh();
  }

  void remove(OnscreenPosition position) {
    _elements.remove(position);

    if (_focusedPosition == position) {
      notifyListeners();
    }

    _refresher?.refresh();
  }

  bool hasElement(OnscreenPosition position) {
    return _elements.containsKey(position);
  }

  OnscreenRefresher? _refresher;

  void attach(OnscreenRefresher refresher) {
    _refresher = refresher;
  }

  void detach() {
    _refresher = null;
  }
}

mixin OnscreenRefresher<T extends StatefulWidget> on State<T> {
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }
}
