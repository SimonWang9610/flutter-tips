import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const int _kVisibilityTolerance = 1;

typedef KeyboardStickyChildBuilder = Widget Function(
  BuildContext context,
  KeyboardStickyController controller,
);

typedef KeyboardStickyTextFieldBuilder = Widget Function(
  BuildContext context,
  TextEditingController controller,
  FocusNode focusNode,
);

abstract class KeyboardStickyController {
  bool get visible;
  double get keyboardHeight;

  void showFloating();
  void hideFloating();
}

/// A widget that sticks to the keyboard when the keyboard would overlap or hide it.
///
/// Typically, it should be used when the current widget cannot resize itself
/// to avoid the bottom insets, like [Scaffold.resizeToAvoidBottomInset] is set to false.
///
/// More importantly, the soft keyboard must be shown;
/// otherwise, the floating widget will not be shown automatically or have unexpected behaviors.
///
/// If this widget has an ancestor [Scrollable], it will not show the floating widget, and he original field is always marked as visible,
/// as it is hard to determine if the original field is resizing or its scrollable ancestor is scrolling to show it.
abstract base class KeyboardSticky extends StatefulWidget {
  const KeyboardSticky({super.key});

  /// 3 cases:
  ///
  /// Case 1: both [builder] and [floatingBuilder] are bound the given [controller] and [focusNode] to [TextField]s
  ///
  /// (Show Sticky Floating)
  /// when the [builder]'s [TextField] is focused, the [floatingBuilder] [TextField] may be shown after a small delay (100ms).
  /// As the keyboard is popping up, the device metrics is changed and notified by [WidgetsBindingObserver.didChangeMetrics].
  ///
  /// (Hide Sticky Floating)
  /// 1. Dismissing the keyboard. Like [FocusNode.unfocus] the floating TextField
  /// 2. Invoking [KeyboardStickyController.hideFloating]
  ///
  /// Case 2: [builder] is bound the given [controller] and [focusNode] to [TextField], while [floatingBuilder] shows a non-[TextField] widget
  ///
  /// (Show Sticky Floating)
  /// when the [builder]'s [TextField] is focused, the [floatingBuilder] widget may be shown after a small delay (100ms).
  /// As the keyboard is popping up, the device metrics is changed and notified by [WidgetsBindingObserver.didChangeMetrics].
  ///
  /// (Hide Sticky Floating)
  /// 1. Dismissing the keyboard. Like using [FocusScopeNode.unfocus] to focus another [TextField] or remove all focus.
  /// 2. Invoking [KeyboardStickyController.hideFloating]
  ///
  /// Case 3: [builder] shows a non-[TextField] widget, while [floatingBuilder] shows a [TextField] bound with the given [controller] and [focusNode]
  ///
  /// (Show Sticky Floating)
  /// Invoking [KeyboardStickyController.showFloating] to show the floating widget,
  /// and meanwhile, the floating [TextField] would use [FocusNode.requestFocus] to focus itself so as to show the keyboard.
  ///
  /// (Hide Sticky Floating)
  /// 1. Dismissing the keyboard. Like [FocusNode.unfocus] the floating TextField
  /// 2. Invoking [KeyboardStickyController.hideFloating]
  ///
  /// NOTE: For case 3, it is users' responsibility to manage the floating widget properly.
  const factory KeyboardSticky.field({
    Key? key,
    required KeyboardStickyTextFieldBuilder builder,
    KeyboardStickyTextFieldBuilder? floatingBuilder,
    TextEditingController? controller,
    FocusNode? focusNode,
    FocusNode? floatingFocusNode,
  }) = _KeyboardStickyField;

  // const factory KeyboardSticky.custom({
  //   Key? key,
  //   required KeyboardStickyChildBuilder builder,
  //   required KeyboardStickyChildBuilder floatingBuilder,
  // }) = _KeyboardStickyCustomized;

  static KeyboardStickyController? of(BuildContext context) {
    final widget = context.widget is KeyboardSticky;

    if (widget) {
      return (context as StatefulElement).state as _KeyboardStickyFieldState;
    }

    return context.findAncestorStateOfType<KeyboardStickyState>();
  }
}

final class _KeyboardStickyField extends KeyboardSticky {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? floatingFocusNode;
  final KeyboardStickyTextFieldBuilder builder;
  final KeyboardStickyTextFieldBuilder? floatingBuilder;

  const _KeyboardStickyField({
    super.key,
    required this.builder,
    this.controller,
    this.focusNode,
    this.floatingFocusNode,
    this.floatingBuilder,
  });

  @override
  State<_KeyboardStickyField> createState() => _KeyboardStickyFieldState();
}

final class _KeyboardStickyFieldState
    extends KeyboardStickyState<_KeyboardStickyField> {
  FocusNode? _firstFocusNode;
  FocusNode? _secondFocusNode;
  TextEditingController? _defaultController;

  FocusNode get _originalFocusNode =>
      widget.focusNode ?? (_firstFocusNode ??= FocusNode());
  FocusNode get _floatingFocusNode =>
      widget.floatingFocusNode ?? (_secondFocusNode ??= FocusNode());

  TextEditingController get _controller =>
      widget.controller ?? (_defaultController ??= TextEditingController());

  @override
  void initState() {
    super.initState();

    _visible.addListener(_autoShowing);

    _floatingFocusNode.addListener(_autoHiding);
  }

  @override
  void didUpdateWidget(covariant _KeyboardStickyField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.floatingFocusNode != _floatingFocusNode) {
      oldWidget.floatingFocusNode?.removeListener(_autoHiding);
      // ensure we do not add the same listener twice
      _floatingFocusNode.removeListener(_autoHiding);
      _floatingFocusNode.addListener(_autoHiding);
    }

    if (oldWidget.focusNode != _originalFocusNode) {
      oldWidget.focusNode?.removeListener(_autoShowing);
      // ensure we do not add the same listener twice
      _originalFocusNode.removeListener(_autoShowing);
      _originalFocusNode.addListener(_autoShowing);
    }

    if (oldWidget.controller != widget.controller ||
        oldWidget.floatingBuilder != widget.floatingBuilder ||
        oldWidget.builder != widget.builder) {
      _rebuildFloating();
    }
  }

  void _autoHiding() {
    if (!_floatingFocusNode.hasFocus) {
      _revokeScheduling();
      debugPrint("[Floating] -> hiding");
      hideFloating();
    }
  }

  Timer? _debounce;

  void _autoShowing() {
    if (!_visible.value && (_originalFocusNode.hasFocus)) {
      _scheduleShowing();
    } else if (!_floatingFocusNode.hasFocus) {
      _revokeScheduling();
      debugPrint("[Original] -> hiding");
      hideFloating();
    }
  }

  void _revokeScheduling() {
    _debounce?.cancel();
    _debounce = null;
  }

  ///! some aspects may introduce unexpected fluctuations of the calculation of the visibility in [didChangeMetrics]
  /// so we hope to eliminate the fluctuations as much as possible by delaying showing the floating field,
  /// thereby avoiding showing the floating field unexpectedly.
  void _scheduleShowing() {
    if (_debounce != null && _debounce!.isActive) return;
    _debounce = Timer(const Duration(milliseconds: 100), () {
      debugPrint("[Original] -> showing");
      showFloating();
    });
  }

  @override
  void dispose() {
    _firstFocusNode?.dispose();
    _secondFocusNode?.dispose();
    _defaultController?.dispose();
    super.dispose();
  }

  @override
  void showFloating() {
    super.showFloating();
    if (!_floatingFocusNode.hasFocus) {
      _floatingFocusNode.requestFocus();
      debugPrint("Requesting focus to Floating Focus Node");
    }
  }

  @override
  Widget _buildFloating(BuildContext context) {
    final builder = widget.floatingBuilder ?? widget.builder;

    return Material(
      child: builder(context, _controller, _floatingFocusNode),
    );
  }

  @override
  Widget _buildChild(BuildContext context) {
    return widget.builder(context, _controller, _originalFocusNode);
  }
}

final class _KeyboardStickyCustomized extends KeyboardSticky {
  final KeyboardStickyChildBuilder builder;
  final KeyboardStickyChildBuilder floatingBuilder;

  const _KeyboardStickyCustomized({
    super.key,
    required this.builder,
    required this.floatingBuilder,
  });

  @override
  State<_KeyboardStickyCustomized> createState() =>
      _KeyboardStickyCustomizedState();
}

final class _KeyboardStickyCustomizedState
    extends KeyboardStickyState<_KeyboardStickyCustomized> {
  @override
  void initState() {
    super.initState();
    // keyboardHeight.addListener(_autoHiding);
    _visible.addListener(_autoHiding);
  }

  @override
  void didUpdateWidget(covariant _KeyboardStickyCustomized oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.floatingBuilder != widget.floatingBuilder ||
        oldWidget.builder != widget.builder) {
      _rebuildFloating();
    }
  }

  void _autoHiding() {
    if (_visible.value) {
      hideFloating();
    }
  }

  @override
  Widget _buildFloating(BuildContext context) {
    return widget.floatingBuilder(context, this);
  }

  @override
  Widget _buildChild(BuildContext context) {
    return widget.builder(context, this);
  }
}

abstract base class KeyboardStickyState<T extends KeyboardSticky>
    extends State<T>
    with WidgetsBindingObserver
    implements KeyboardStickyController {
  final ValueNotifier<bool> _visible = ValueNotifier(true);
  final ValueNotifier<double> _keyboardHeight = ValueNotifier(0);

  @override
  bool get visible => _visible.value;

  @override
  double get keyboardHeight => _keyboardHeight.value;

  Size _screenSize = Size.zero;

  Size get screenSize => _screenSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkIfAncestorScrollable();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkIfAncestorScrollable();
  }

  @override
  @override
  void dispose() {
    _floating?.dispose();
    _floating = null;
    _keyboardHeight.dispose();
    _visible.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  double _fieldLastTrailing = 0;

  /// Two cases when the keyboard is popping up:
  ///
  /// Case 1 (the original field needs to resize):
  ///
  /// Position change: [leading, trailing, keyboard] -> [leading, trailing, keyboard] -> [leading, keyboard, trailing] ... -> [leading, trailing, keyboard]
  ///
  /// During keyboard transition, the original field will be resized to avoid the bottom insets.
  /// Since the trailing always changes before the leading, we can determine the resizing by comparing the changes of the trailing.
  ///
  /// Case 2 (original field is not resized):
  ///
  /// Position change: [leading, trailing, keyboard] -> [leading, keyboard, trailing] -> [keyboard, leading, trailing]
  ///
  /// We will show the floating field when the original field is focused and not visible totally.
  ///
  /// Note: if the original field has a scrollable ancestor, we will not show the floating field,
  /// and always mark the original field as visible,
  /// as it is hard to determine if the original field is resizing or its scrollable ancestor is scrolling to show it.
  @override
  void didChangeMetrics() {
    final view = View.of(context);

    final physicalBottomInsets = view.viewInsets.bottom;
    final pixelRatio = view.devicePixelRatio;

    _screenSize = view.physicalSize / pixelRatio;
    _keyboardHeight.value = (physicalBottomInsets / pixelRatio).roundToDouble();

    final (leading, trailing) = _findRenderLeadingAndTrailing();
    final resizing =
        (trailing - _fieldLastTrailing).abs() > _kVisibilityTolerance;
    final visibleEdge = _screenSize.height - _keyboardHeight.value;

    _fieldLastTrailing = trailing;

    _visible.value = _ancestorScrollable ||
        resizing ||
        visibleEdge - leading > -_kVisibilityTolerance;

    print(
        "visible: ${_visible.value}, ${visibleEdge >= leading}/${visibleEdge >= trailing}, scrollable: $_ancestorScrollable");
  }

  (double, double) _findRenderLeadingAndTrailing() {
    final renderObject = context.findRenderObject() as RenderBox?;

    if (renderObject != null) {
      final size = renderObject.size;
      final topLeft = renderObject.localToGlobal(Offset.zero);

      return (
        topLeft.dy.roundToDouble(),
        topLeft.dy.roundToDouble() + size.height.round()
      );
    }

    return (0, 0);
  }

  bool _ancestorScrollable = false;

  void _checkIfAncestorScrollable() {
    final position = Scrollable.maybeOf(context)?.position;

    // if (position == null || !position.hasPixels) {
    //   return false;
    // } else {
    //   return position.pixels != 0;
    // }

    _ancestorScrollable = position != null;
  }

  OverlayEntry? _floating;

  @override
  void showFloating() {
    if (_floating != null) {
      return;
    }
    _floating = OverlayEntry(
      builder: (context) => ValueListenableBuilder(
        valueListenable: _keyboardHeight,
        builder: (inner, height, child) => Positioned(
          bottom: height,
          width: screenSize.width,
          child: _buildFloating(inner),
        ),
      ),
    );
    Overlay.of(context).insert(_floating!);
  }

  @override
  void hideFloating() {
    _floating?.remove();
    _floating = null;
  }

  void _rebuildFloating() {
    if (_floating != null) {
      if (WidgetsBinding.instance.schedulerPhase ==
          SchedulerPhase.postFrameCallbacks) {
        _floating?.markNeedsBuild();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _floating?.markNeedsBuild();
        });
      }
    }
  }

  Widget _buildFloating(BuildContext context);

  Widget _buildChild(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);

    return ValueListenableBuilder(
      valueListenable: _visible,
      builder: (_, visible, child) {
        return Offstage(
          offstage: !visible,
          child: child,
        );
      },
      child: child,
    );
  }
}
