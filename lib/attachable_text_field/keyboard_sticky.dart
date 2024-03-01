import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tips/attachable_text_field/field_builder_delegate.dart';

const int _kVisibilityTolerance = 1;

abstract mixin class KeyboardStickyController {
  bool get visible;
  double get keyboardHeight;

  void showFloating();
  void hideFloating();
}

/// A widget that sticks to the keyboard when the keyboard would overlap or hide it.
///
/// Typically, it should be used when the current widget cannot resize itself
/// to avoid the bottom insets, like [Scaffold.resizeToAvoidBottomInset] is set as false.
///
/// More importantly, the soft keyboard must be shown;
/// otherwise, the floating widget will not be shown automatically
/// unless [KeyboardStickyController.showFloating] is called manually
/// (this way may have unexpected behaviors if developers do not understand how [KeyboardSticky] works).
///
/// If this widget has an ancestor [Scrollable], it will not show the floating widget,
/// and he original widget is always marked as visible,
/// as it is hard to determine if the original widget is resizing or its scrollable ancestor is scrolling to show it.
///
/// Prefer to use [KeyboardSticky.single] or [KeyboardSticky.both] to create a [KeyboardSticky] widget,
/// unless you want to create a custom [KeyboardSticky] widget an understand how it works totally.
///
/// See also:
/// - [KeyboardSticky.single]
/// - [KeyboardSticky.both]
class KeyboardSticky extends StatefulWidget {
  /// Whether to use [Material] as the wrapper of the floating widget.
  /// Typically, [Material] is required if the floating widget contains a [TextField].
  final bool useMaterial;

  /// The delegate that builds the original widget showing when the keyboard is not visible.
  final KeyboardStickyChildBuilderDelegate delegate;

  /// The delegate that builds the floating widget showing
  /// when the keyboard is visible and the original widget is not visible totally.
  final KeyboardStickyChildBuilderDelegate floatingDelegate;

  const KeyboardSticky({
    super.key,
    required this.delegate,
    required this.floatingDelegate,
    this.useMaterial = true,
  });

  /// A shortcut to create a [KeyboardSticky] that only shows one [TextField] either in the original or floating widget.
  ///
  /// if [forFloating] is true, [fieldBuilder] will be used to build a [TextField] used by [builder];
  /// otherwise, [fieldBuilder] will be used to build a [TextField] used by [floatingBuilder].
  ///
  /// The original widget built from [builder] will be shown when the keyboard is not visible.
  /// The floating widget built from [floatingBuilder] will be shown when the keyboard is visible and the original widget is not visible.
  ///
  /// [controller] would be bound with [fieldBuilder] if provided.
  ///
  /// [focusNode] would be bound with [fieldBuilder] if provided and [forFloating] is false.
  ///
  /// [floatingFocusNode] would be bound with [floatingBuilder] if provided and [forFloating] is true.
  ///
  /// If [forFloating] is true, and the original widget will not include a [TextField],
  /// it is user's responsibility to manage the floating widget properly via [KeyboardStickyController].
  ///
  /// Please be sure to use the given [FocusNode] in the [TextField] built from [fieldBuilder],
  /// so as to listen to the focus changes and then show/hide the floating widget automatically.
  /// Through this way, you do not need to manage the floating widget manually via [KeyboardStickyController].
  KeyboardSticky.single({
    super.key,
    FocusNode? focusNode,
    TextEditingController? controller,
    FocusNode? floatingFocusNode,
    bool forFloating = false,
    this.useMaterial = true,
    required KeyboardStickyWrapperBuilder builder,
    required KeyboardStickyWrapperBuilder floatingBuilder,
    required KeyboardStickyFieldBuilder fieldBuilder,
  })  : delegate = KeyboardStickyChildBuilderDelegate(
          wrapperBuilder: builder,
          fieldBuilder: !forFloating ? fieldBuilder : null,
          focusNode: focusNode,
          controller: controller,
        ),
        floatingDelegate = KeyboardStickyChildBuilderDelegate(
          wrapperBuilder: floatingBuilder,
          fieldBuilder: forFloating ? fieldBuilder : null,
          focusNode: floatingFocusNode,
          controller: controller,
        );

  /// A shortcut to create a [KeyboardSticky] that shows two [TextField]s in both the original and floating widgets.
  ///
  /// If [floatingBuilder] is not provided, [builder] will also be used to build the floating widget.
  /// If [floatingFieldBuilder] is not provided, [fieldBuilder] will also be used to build the floating [TextField].
  ///
  /// The original/floating [TextField] should share the same [controller] so that they can share the same text value.
  /// Therefore, [controller] would be used by both [fieldBuilder] and [floatingFieldBuilder] if provided;
  /// otherwise, a default [TextEditingController] will be created for them.
  ///
  /// However, the two [TextField]s should have different [FocusNode]s so that they can be focused separately.
  /// Therefore, [focusNode] would be used by [fieldBuilder] if provided, while [floatingFocusNode] would be used by [floatingFieldBuilder] if provided.
  ///
  /// Please be sure to use the given [FocusNode] in the [TextField] built from [fieldBuilder]/[floatingFieldBuilder].
  KeyboardSticky.both({
    super.key,
    FocusNode? focusNode,
    TextEditingController? controller,
    FocusNode? floatingFocusNode,
    TextEditingController? floatingController,
    this.useMaterial = true,
    required KeyboardStickyWrapperBuilder builder,
    required KeyboardStickyFieldBuilder fieldBuilder,
    KeyboardStickyWrapperBuilder? floatingBuilder,
    KeyboardStickyFieldBuilder? floatingFieldBuilder,
  })  : delegate = KeyboardStickyChildBuilderDelegate(
          wrapperBuilder: builder,
          fieldBuilder: fieldBuilder,
          focusNode: focusNode,
          controller: controller,
        ),
        floatingDelegate = KeyboardStickyChildBuilderDelegate(
          wrapperBuilder: floatingBuilder ?? builder,
          fieldBuilder: floatingFieldBuilder ?? fieldBuilder,
          focusNode: floatingFocusNode,
          controller: floatingController,
        );

  @override
  State<KeyboardSticky> createState() => _DelegatedKeyboardStickyState();

  static KeyboardStickyController? of(BuildContext context) {
    final widget = context.widget is KeyboardSticky;

    if (widget) {
      return (context as StatefulElement).state
          as _DelegatedKeyboardStickyState;
    }

    return context.findAncestorStateOfType<KeyboardStickyState>();
  }
}

abstract base class KeyboardStickyState<T extends KeyboardSticky>
    extends State<T>
    with WidgetsBindingObserver
    implements KeyboardStickyController {
  final ValueNotifier<bool> visibility = ValueNotifier(true);
  final ValueNotifier<double> keyboard = ValueNotifier(0);

  @override
  bool get visible => visibility.value;

  @override
  double get keyboardHeight => keyboard.value;

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
    keyboard.dispose();
    visibility.dispose();
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
    keyboard.value = (physicalBottomInsets / pixelRatio).roundToDouble();

    final (leading, trailing) = _findRenderLeadingAndTrailing();
    final resizing =
        (trailing - _fieldLastTrailing).abs() > _kVisibilityTolerance;
    final visibleEdge = _screenSize.height - keyboard.value;

    _fieldLastTrailing = trailing;

    visibility.value = _ancestorScrollable ||
        resizing ||
        visibleEdge - leading > -_kVisibilityTolerance;

    debugPrint(
        "visible: $visible, ${visibleEdge >= leading}/${visibleEdge >= trailing}, scrollable: $_ancestorScrollable");
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
        valueListenable: keyboard,
        builder: (inner, height, child) => Positioned(
          bottom: height,
          width: screenSize.width,
          child: buildFloating(inner),
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

  Widget buildFloating(BuildContext context);

  Widget buildChild(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final child = buildChild(context);

    return ValueListenableBuilder(
      valueListenable: visibility,
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

final class _DelegatedKeyboardStickyState
    extends KeyboardStickyState<KeyboardSticky> {
  FocusNode? _firstFocusNode;
  FocusNode? _secondFocusNode;
  TextEditingController? _defaultController;

  FocusNode get _originalFocusNode =>
      widget.delegate.focusNode ?? (_firstFocusNode ??= FocusNode());
  FocusNode get _floatingFocusNode =>
      widget.floatingDelegate.focusNode ?? (_secondFocusNode ??= FocusNode());

  TextEditingController get _originalController =>
      widget.delegate.controller ??
      (_defaultController ??= TextEditingController());

  TextEditingController get _floatingController =>
      widget.floatingDelegate.controller ??
      (_defaultController ??= TextEditingController());

  @override
  void initState() {
    super.initState();

    visibility.addListener(_autoShowing);

    _floatingFocusNode.addListener(_autoHiding);
  }

  @override
  void didUpdateWidget(covariant KeyboardSticky oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.floatingDelegate.focusNode !=
        widget.floatingDelegate.focusNode) {
      oldWidget.floatingDelegate.focusNode?.removeListener(_autoHiding);
      widget.floatingDelegate.focusNode?.removeListener(_autoHiding);
      _secondFocusNode?.removeListener(_autoHiding);

      _floatingFocusNode.addListener(_autoHiding);
    }

    if (oldWidget.delegate.focusNode != widget.delegate.focusNode) {
      oldWidget.delegate.focusNode?.removeListener(_autoShowing);
      widget.delegate.focusNode?.removeListener(_autoShowing);
      _firstFocusNode?.removeListener(_autoShowing);

      _originalFocusNode.addListener(_autoShowing);
    }

    if (oldWidget.floatingDelegate != widget.floatingDelegate ||
        oldWidget.useMaterial != widget.useMaterial) {
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
    if (!visible && (_originalFocusNode.hasFocus)) {
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
    _revokeScheduling();
    _firstFocusNode?.dispose();
    _secondFocusNode?.dispose();
    _defaultController?.dispose();
    super.dispose();
  }

  @override
  void showFloating() {
    if (!_hasFloatingField && !_hasOriginalField) {
      debugPrint(
        "[WARNING]: No [TextField] for original and floating widgets."
        "If you want to include [TextField], please provide [fieldBuilder]/[floatingFieldBuilder] for them,"
        "instead of building [TextField] in [builder]/[floatingBuilder].",
      );
    }

    super.showFloating();
    if (!_floatingFocusNode.hasFocus) {
      _floatingFocusNode.requestFocus();
      debugPrint("Requesting focus to Floating Focus Node");
    }
  }

  bool _hasOriginalField = false;
  bool _hasFloatingField = false;

  @override
  Widget buildFloating(BuildContext context) {
    final delegate = widget.floatingDelegate;

    final field = delegate.fieldBuilder?.call(
      context,
      _floatingController,
      _floatingFocusNode,
    );

    _hasFloatingField = field != null;

    final child = delegate.build(context, this, field);

    return widget.useMaterial
        ? Material(
            type: MaterialType.transparency,
            child: child,
          )
        : child;
  }

  @override
  Widget buildChild(BuildContext context) {
    final field = widget.delegate.fieldBuilder?.call(
      context,
      _originalController,
      _originalFocusNode,
    );

    _hasOriginalField = field != null;

    return widget.delegate.build(context, this, field);
  }
}
