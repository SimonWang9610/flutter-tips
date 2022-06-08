import 'dart:math';
import 'package:flutter/material.dart';

typedef IndexedAnimationCallback = void Function(int);
typedef TransitionBuilder = Widget Function(
    BuildContext, Animation<double>, int, Widget?);
typedef ItemBuilder = Widget Function(BuildContext, int);

typedef SeparatorBuilder = Widget Function(BuildContext context, int index);

enum ItemIndexPolicy {
  before,
  after,
  none,
}

enum ListOperation {
  insert,
  remove,
  reorder,
}

class CustomAnimatedList extends StatefulWidget {
  final int initItemCount;
  final Duration? duration;
  final ScrollController? scrollController;
  final Axis scrollDirection;
  final bool shrinkWrap;
  final Clip clipBehavior;

  /// if want to keep item alive after re-ordering
  /// must provide[findChildIndex] to reuse the built item widgets
  final ChildIndexGetter? findChildIndex;

  /// currently, [transitionBuilder] only support [double] type [Animation]
  /// if [transitionBuilder] is null, it will fallback to [itemBuilder]
  final TransitionBuilder? transitionBuilder;
  final SeparatorBuilder? separatedBuilder;
  final ItemBuilder itemBuilder;

  /// if true, the first widget should be a separator
  /// and [itemIndexPolicy] should be [ItemIndexPolicy.before]
  /// as a result, both the first and last widgets of the list would be separators
  final bool initWithSeparator;
  final Curve curve;

  /// indicate the item should before or after the separator
  /// if none, [separatedBuilder] will be ignored, and the [index] will be the actual index of items
  final ItemIndexPolicy itemIndexPolicy;
  const CustomAnimatedList({
    Key? key,
    required this.itemBuilder,
    this.separatedBuilder,
    this.duration,
    this.findChildIndex,
    this.transitionBuilder,
    this.scrollController,
    this.initItemCount = 0,
    this.clipBehavior = Clip.hardEdge,
    this.shrinkWrap = false,
    this.initWithSeparator = false,
    this.scrollDirection = Axis.vertical,
    this.curve = Curves.easeIn,
    this.itemIndexPolicy = ItemIndexPolicy.none,
  })  : assert(
          itemIndexPolicy == ItemIndexPolicy.none ||
              separatedBuilder != null &&
                  itemIndexPolicy != ItemIndexPolicy.none,
        ),
        assert(
          !initWithSeparator ||
              initWithSeparator &&
                  itemIndexPolicy == ItemIndexPolicy.before &&
                  separatedBuilder != null,
        ),
        super(key: key);

  @override
  State<CustomAnimatedList> createState() => CustomAnimatedListState();
}

class CustomAnimatedListState extends State<CustomAnimatedList>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  /// the total number of the widgets in the list
  /// if [widget.separatedBuilder] not null and not [ItemIndexPolicy.none]
  /// it will double as the number of items
  late int _childCount;

  /// the index we should enable animation
  int? _activeIndex;

  late final bool _itemIndexEven;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration ??
          const Duration(
            milliseconds: 300,
          ),
    );

    _activeIndex = widget.initItemCount > 0 ? widget.initItemCount - 1 : null;

    _itemIndexEven = widget.itemIndexPolicy == ItemIndexPolicy.before &&
        !widget.initWithSeparator;

    if (widget.initWithSeparator) {
      _childCount = 2 * widget.initItemCount + 1;
    } else if (widget.separatedBuilder != null) {
      _childCount = 2 * widget.initItemCount;
    } else {
      _childCount = widget.initItemCount;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      controller: widget.scrollController,
      shrinkWrap: widget.shrinkWrap,
      clipBehavior: widget.clipBehavior,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverList(
          delegate: _createDelegate(),
        ),
      ],
    );
  }

  void animateTo(int index, ListOperation operation) {
    switch (operation) {
      case ListOperation.insert:
        if (widget.itemIndexPolicy == ItemIndexPolicy.none) {
          _childCount++;
        } else {
          _childCount += 2;
        }
        break;
      case ListOperation.remove:
        if (widget.itemIndexPolicy == ItemIndexPolicy.none) {
          _childCount--;
        } else {
          _childCount -= 2;
        }
        break;
      default:
        break;
    }

    _activeIndex = index;
    controller.reset();
    setState(() {
      controller.forward();
    });
  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate(
      (BuildContext context, index) {
        switch (widget.itemIndexPolicy) {
          case ItemIndexPolicy.none:
            return _buildItem(context, index);
          default:
            return _buildWithSeparator(context, index);
        }
      },
      childCount: _childCount,
      findChildIndexCallback: widget.findChildIndex,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    if (widget.transitionBuilder != null) {
      final animation = _createAnimation(index);
      return widget.transitionBuilder!.call(
        context,
        animation,
        index,
        widget.itemBuilder(
          context,
          index,
        ),
      );
    } else {
      return widget.itemBuilder(context, index);
    }
  }

  Widget _buildWithSeparator(BuildContext context, int index) {
    assert(
        widget.itemIndexPolicy != ItemIndexPolicy.none &&
            widget.separatedBuilder != null,
        '${widget.itemIndexPolicy} required a [separatedBuilder]');
    final effectiveIndex = index ~/ 2;

    return (_itemIndexEven && index.isEven || !_itemIndexEven && index.isOdd)
        ? _buildItem(context, effectiveIndex)
        : widget.separatedBuilder!.call(context, effectiveIndex);
  }

  /// here, we could return different [Animation] for each item widget
  /// animations of all item widgets will be driven by the same [AnimationController]
  Animation<double> _createAnimation(int index) {
    if (index == _activeIndex) {
      return CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      );
    } else {
      return AlwaysStoppedAnimation<double>(controller.upperBound);
    }
  }
}
