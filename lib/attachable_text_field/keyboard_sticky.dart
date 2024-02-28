import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

typedef KeyboardStickyChildBuilder = Widget Function(
  BuildContext context,
  KeyboardStickyFloatingController controller,
);

typedef KeyboardStickyTextFieldBuilder = Widget Function(
  BuildContext context,
  TextEditingController controller,
  FocusNode focusNode,
);

abstract class KeyboardStickyFloatingController {
  bool get visible;
  double get keyboardHeight;

  void showFloating();
  void hideFloating();
}

abstract base class KeyboardSticky extends StatefulWidget {
  const KeyboardSticky({super.key});

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
      hideFloating();
    }
  }

  void _autoShowing() {
    if (!_visible.value && _originalFocusNode.hasFocus) {
      showFloating();
    } else {
      hideFloating();
    }
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
    implements KeyboardStickyFloatingController {
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

  @override
  void didChangeMetrics() {
    final view = View.of(context);

    final physicalBottomInsets = view.viewInsets.bottom;
    final pixelRatio = view.devicePixelRatio;

    _screenSize = view.physicalSize / pixelRatio;
    _keyboardHeight.value = (physicalBottomInsets / pixelRatio).roundToDouble();

    final (leading, trailing) = _findRenderLeadingAndTrailing();
    final resizing = (trailing - _fieldLastTrailing).abs() > 1;
    final visibleEdge = _screenSize.height - _keyboardHeight.value;

    _fieldLastTrailing = trailing;
    _visible.value = resizing || visibleEdge - leading > -1;

    print('visible: ${_visible.value}, keyboard: ${_keyboardHeight.value}, ');
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
