import 'dart:async';
import 'package:flutter/material.dart';

const int _kVisibleTolerance = -1;

class _SaltKey extends LocalKey {
  final Key key;
  const _SaltKey(this.key);
}

class StickyTextField extends StatefulWidget {
  final TextField textField;
  final FocusNode? floatingFocusNode;
  const StickyTextField({
    super.key,
    required this.textField,
    this.floatingFocusNode,
  });

  @override
  State<StickyTextField> createState() => StickyTextFieldState();
}

class StickyTextFieldState extends State<StickyTextField>
    with WidgetsBindingObserver {
  FocusNode? _firstFocusNode;
  FocusNode? _secondFocusNode;
  TextEditingController? _defaultController;

  FocusNode get _originalFocusNode =>
      widget.textField.focusNode ?? (_firstFocusNode ??= FocusNode());
  FocusNode get _floatingFocusNode =>
      widget.floatingFocusNode ?? (_secondFocusNode ??= FocusNode());

  TextEditingController get _controller =>
      widget.textField.controller ??
      (_defaultController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _visible.addListener(_show);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _floatingField?.dispose();
    _debounce = null;
    _floatingField = null;
    _visible.removeListener(_show);
    _keyboardLogicHeight.dispose();
    _visible.dispose();
    _firstFocusNode?.dispose();
    _secondFocusNode?.dispose();
    _defaultController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final ValueNotifier<double> _keyboardLogicHeight = ValueNotifier(0);
  final ValueNotifier<bool> _visible = ValueNotifier(true);

  OverlayEntry? _floatingField;
  Timer? _debounce;

  /// when the page is resized to avoid the bottom insets,
  /// the timer duration too short will cause the floating field to be shown;
  /// in this case, this duration should be greater than 256 ms (about 16 frames);
  void _show() {
    if (!_visible.value && _originalFocusNode.hasFocus) {
      // if (_debounce == null || !_debounce!.isActive) {
      //   _debounce =
      //       Timer(const Duration(milliseconds: 100), _showFloatingField);
      // }
      _showFloatingField();
    } else {
      _debounce?.cancel();
      _debounce = null;
      _floatingField?.remove();
      _floatingField = null;
    }
  }

  void _showFloatingField() {
    if (_floatingField != null) {
      return;
    }
    print(" floating text field shown");

    _floatingField = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder(
          valueListenable: _keyboardLogicHeight,
          builder: (_, height, child) {
            return Positioned(
              bottom: height,
              width: _screenSize.width,
              child: Material(
                elevation: 4,
                child: child,
              ),
            );
          },
          child: _copyField(
            _floatingFocusNode,
            _controller,
            key: _floatingKey,
          ),
        );
      },
    );
    Overlay.of(context).insert(_floatingField!);
    if (!_floatingFocusNode.hasFocus) {
      _floatingFocusNode.requestFocus();
    }
  }

  Size _screenSize = Size.zero;

  /// during resizing, the trailing would always change before the leading
  /// so we determine the resizing by comparing the changes of the trailing
  double _fieldLastTrailing = 0;

  /// Two cases when the keyboard is popping up:
  ///
  /// Case 1 (the original field needs to resize):
  ///
  /// Position change: [leading, trailing, keyboard] -> [leading, keyboard, trailing] ... -> [leading, trailing, keyboard]
  ///
  /// During keyboard transition, the original field will be resized to avoid the bottom insets.
  /// However, the part of the original field may be overlapped by the keyboard,
  /// e.g., [leading, keyboard, trailing] for i frame, the keyboard will overlap with the original field
  /// [leading, trailing, keyboard] for i+1 frame, the keyboard will below the original field.
  /// Since the trailing always changes before the leading, we can determine the resizing by comparing the changes of the trailing.
  ///
  /// Case 2 (original field is not resized):
  ///
  /// Position change: [leading, trailing, keyboard] -> [leading, keyboard, trailing] -> [keyboard, leading, trailing]
  ///
  /// We will show the floating field when the original field is focused and not visible totally.
  @override
  void didChangeMetrics() {
    final view = View.of(context);

    final physicalBottomInsets = view.viewInsets.bottom;
    final pixelRatio = view.devicePixelRatio;

    _screenSize = view.physicalSize / pixelRatio;
    _keyboardLogicHeight.value =
        (physicalBottomInsets / pixelRatio).roundToDouble();

    final (leading, trailing) = _findRenderLeadingAndTrailing();
    final resizing = (trailing - _fieldLastTrailing).abs() > 1;
    final visibleEdge = _screenSize.height - _keyboardLogicHeight.value;

    _fieldLastTrailing = trailing;
    _visible.value = resizing || visibleEdge - leading > _kVisibleTolerance;

    print(
        'visible: ${_visible.value}, keyboard: ${_keyboardLogicHeight.value}, ');
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

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (widget.textField.focusNode == _originalFocusNode &&
        widget.textField.controller == _controller) {
      child = widget.textField;
    } else {
      child = _copyField(
        _originalFocusNode,
        _controller,
        key: _originalKey,
      );
    }

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

  _SaltKey? get _floatingKey {
    final key = widget.textField.key;
    return key != null ? _SaltKey(key) : null;
  }

  _SaltKey? get _originalKey {
    final key = widget.textField.key;
    return key != null ? _SaltKey(key) : null;
  }

  TextField _copyField(FocusNode focusNode, TextEditingController controller,
      {Key? key}) {
    return TextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      decoration: widget.textField.decoration,
      keyboardType: widget.textField.keyboardType,
      textInputAction: widget.textField.textInputAction,
      textCapitalization: widget.textField.textCapitalization,
      style: widget.textField.style,
      strutStyle: widget.textField.strutStyle,
      textAlign: widget.textField.textAlign,
      textAlignVertical: widget.textField.textAlignVertical,
      textDirection: widget.textField.textDirection,
      readOnly: widget.textField.readOnly,
      showCursor: widget.textField.showCursor,
      autofocus: widget.textField.autofocus,
      obscuringCharacter: widget.textField.obscuringCharacter,
      obscureText: widget.textField.obscureText,
      autocorrect: widget.textField.autocorrect,
      smartDashesType: widget.textField.smartDashesType,
      smartQuotesType: widget.textField.smartQuotesType,
      enableSuggestions: widget.textField.enableSuggestions,
      maxLines: widget.textField.maxLines,
      minLines: widget.textField.minLines,
      expands: widget.textField.expands,
      maxLength: widget.textField.maxLength,
      maxLengthEnforcement: widget.textField.maxLengthEnforcement,
      onChanged: widget.textField.onChanged,
      onEditingComplete: widget.textField.onEditingComplete,
      onSubmitted: widget.textField.onSubmitted,
      onAppPrivateCommand: widget.textField.onAppPrivateCommand,
      inputFormatters: widget.textField.inputFormatters,
      enabled: widget.textField.enabled,
      cursorWidth: widget.textField.cursorWidth,
      cursorHeight: widget.textField.cursorHeight,
      cursorRadius: widget.textField.cursorRadius,
      cursorOpacityAnimates: widget.textField.cursorOpacityAnimates,
      cursorColor: widget.textField.cursorColor,
      selectionHeightStyle: widget.textField.selectionHeightStyle,
      selectionWidthStyle: widget.textField.selectionWidthStyle,
      keyboardAppearance: widget.textField.keyboardAppearance,
      scrollPadding: widget.textField.scrollPadding,
      dragStartBehavior: widget.textField.dragStartBehavior,
      enableInteractiveSelection: widget.textField.enableInteractiveSelection,
      selectionControls: widget.textField.selectionControls,
      onTap: widget.textField.onTap,
      onTapOutside: widget.textField.onTapOutside,
      mouseCursor: widget.textField.mouseCursor,
      buildCounter: widget.textField.buildCounter,
      scrollController: widget.textField.scrollController,
      scrollPhysics: widget.textField.scrollPhysics,
      autofillHints: widget.textField.autofillHints,
      clipBehavior: widget.textField.clipBehavior,
      restorationId: widget.textField.restorationId,
    );
  }
}
