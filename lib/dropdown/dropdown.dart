import 'package:flutter/material.dart' hide DropdownButtonBuilder;
import 'controller.dart';
import 'menu_builder_delegate.dart';
import 'models.dart';

/// todo: support animating the dropdown menu
class Dropdown<T> extends StatefulWidget {
  /// The widget that will be used to trigger the dropdown.
  /// It can be a button, a text field, or any other widget.
  final WidgetBuilder builder;
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
  final bool enableListen;

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
    this.enableListen = true,
  });

  Dropdown.list({
    super.key,
    required this.builder,
    required this.controller,
    this.menuConstraints,
    this.menuDecoration,
    this.enableListen = true,
    this.menuPosition = const DropdownMenuPosition(),
    this.crossAxisConstrained = true,
    this.dismissible = true,
    this.enabled = true,
    required MenuItemBuilder<T> itemBuilder,
    IndexedWidgetBuilder? separatorBuilder,
    WidgetBuilder? loadingBuilder,
    WidgetBuilder? emptyListBuilder,
  }) : delegate = ListViewMenuBuilderDelegate<T>(
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
    this.enableListen = true,
    this.menuPosition = const DropdownMenuPosition(),
    this.crossAxisConstrained = true,
    this.dismissible = true,
    this.enabled = true,
  }) : delegate = CustomMenuBuilderDelegate<T>(menuBuilder);

  @override
  State<Dropdown<T>> createState() => _DropdownState<T>();
}

class _DropdownState<T> extends State<Dropdown<T>>
    with WidgetsBindingObserver, DropdownOverlayBuilderDelegate {
  final LayerLink _link = LayerLink();

  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant Dropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach();
      widget.controller.attach(this);
    }

    if (oldWidget.menuDecoration != widget.menuDecoration ||
        oldWidget.menuConstraints != widget.menuConstraints ||
        oldWidget.menuPosition != widget.menuPosition ||
        oldWidget.crossAxisConstrained != widget.crossAxisConstrained ||
        oldWidget.dismissible != widget.dismissible ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.delegate != widget.delegate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.rebuildMenu();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.detach();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  OverlayEntry buildMenuOverlay() {
    return OverlayEntry(
      builder: (context) {
        return TapRegion(
          onTapOutside: (event) {
            if (widget.dismissible && !_contain(event.position)) {
              widget.controller.dismiss();
            }
          },
          child: OverlayedDropdownMenu<T>(
            link: _link,
            loading: widget.controller.loading,
            items: widget.controller.currentItems,
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
      link: _link,
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
        child: widget.enableListen
            ? ListenableBuilder(
                listenable: widget.controller,
                builder: (inner, _) => widget.builder(inner),
              )
            : widget.builder(context),
      ),
    );
  }
}
