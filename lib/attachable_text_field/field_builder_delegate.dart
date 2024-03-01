import 'package:flutter/material.dart';
import 'package:flutter_tips/attachable_text_field/keyboard_sticky.dart';

typedef KeyboardStickyFieldBuilder = TextField Function(BuildContext context,
    TextEditingController controller, FocusNode focusNode);

typedef KeyboardStickyWrapperBuilder = Widget Function(BuildContext context,
    KeyboardStickyController controller, TextField? field);

abstract base class KeyboardStickyBuilderDelegate {
  final KeyboardStickyFieldBuilder? fieldBuilder;

  const KeyboardStickyBuilderDelegate({
    this.fieldBuilder,
  });

  Widget build(BuildContext context, KeyboardStickyController controller,
      TextField? field);
}

/// A delegate that builds child or floating child of [KeyboardSticky] with a custom builder.
final class KeyboardStickyChildBuilderDelegate
    extends KeyboardStickyBuilderDelegate {
  /// focus node used by the text field built from [fieldBuilder].
  final FocusNode? focusNode;

  /// controller used by the text field built from [fieldBuilder].
  /// Typically, this controller would be shared by the original and floating text fields.
  final TextEditingController? controller;

  /// builder that builds the wrapper widget for the text field from [fieldBuilder].
  final KeyboardStickyWrapperBuilder wrapperBuilder;

  const KeyboardStickyChildBuilderDelegate({
    required this.wrapperBuilder,
    super.fieldBuilder,
    this.focusNode,
    this.controller,
  });

  @override
  Widget build(BuildContext context, KeyboardStickyController controller,
      TextField? field) {
    return wrapperBuilder(context, controller, field);
  }

  KeyboardStickyChildBuilderDelegate copyWith({
    FocusNode? focusNode,
    TextEditingController? controller,
    KeyboardStickyFieldBuilder? fieldBuilder,
    KeyboardStickyWrapperBuilder? wrapperBuilder,
  }) {
    return KeyboardStickyChildBuilderDelegate(
      focusNode: focusNode ?? this.focusNode,
      controller: controller ?? this.controller,
      fieldBuilder: fieldBuilder ?? this.fieldBuilder,
      wrapperBuilder: wrapperBuilder ?? this.wrapperBuilder,
    );
  }

  @override
  bool operator ==(covariant KeyboardStickyChildBuilderDelegate other) {
    if (identical(this, other)) return true;

    return other.focusNode == focusNode &&
        other.controller == controller &&
        other.fieldBuilder == fieldBuilder &&
        other.wrapperBuilder == wrapperBuilder;
  }

  @override
  int get hashCode {
    return focusNode.hashCode ^
        controller.hashCode ^
        fieldBuilder.hashCode ^
        wrapperBuilder.hashCode;
  }
}
