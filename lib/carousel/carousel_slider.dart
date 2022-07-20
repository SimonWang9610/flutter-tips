import 'package:flutter/material.dart';
import 'models.dart';

class CarouselSlider extends StatefulWidget {
  final Axis scrollDirection;

  /// the ratio of the current center entry occupying its parent width
  /// (which is typically constrained by its parent's [BoxConstraints] and not the real screen width)
  final double viewportFraction;

  final ValueChanged<int>? onPageChanged;
  final List<CarouselEntry> entries;

  /// the ratio of width/height for each entry
  final double? aspectRatio;

  /// [EntryConstraintStrategy.loosen] will try to adapt the size of each entry but not allow overflow its parents's constraints
  /// which is useful when [CarouselEntry.builder] will build its widgets with explicit size;
  /// [EntryConstraintStrategy.tight] will try adapting [aspectRatio] and enforce the size of each entry to be same as its downward constraints
  final EntryConstraintStrategy constraintStrategy;

  /// if enlarge the center entry, [centerScale] will be applied to the center entry
  /// while [sideScale] will be applied to the adjacent entries
  final bool enlargeCenter;

  /// if [enlargeCenter] is false, [centerScale] and [sideScale] will be ignored
  /// if true, the center widget will be scaled to [centerScale]
  /// while its adjacent widgets will be scaled to [sideScale]
  final double centerScale;
  final double sideScale;

  /// if [infiniteScroll] is false, [repeatCount] will be ignored
  /// if true, [repeatCount] will be used to set [PageController.initialPage] which will be equal to
  /// [repeatCount] *  the length of [entries]
  /// because the [PageView] always starts scrolling from 0
  /// so we need setting [PageController.initialPage] intentionally to display the previous entry of [initialPage]
  /// visually making [CarouselSlider] infinite scrolling.
  final bool infiniteScroll;
  final int repeatCount;
  final int initialPage;

  const CarouselSlider({
    Key? key,
    required this.entries,
    this.onPageChanged,
    this.viewportFraction = 0.6,
    this.initialPage = 0,
    this.scrollDirection = Axis.horizontal,
    this.constraintStrategy = EntryConstraintStrategy.tight,
    this.infiniteScroll = true,
    this.enlargeCenter = true,
    this.aspectRatio = 2 / 1,
    this.centerScale = 1.2,
    this.sideScale = 0.8,
    this.repeatCount = 100,
  }) : super(key: key);

  @override
  State<CarouselSlider> createState() => CarouselSliderState();
}

class CarouselSliderState extends State<CarouselSlider> {
  late final PageController controller;

  @override
  void initState() {
    super.initState();
    final int initialPage = widget.infiniteScroll
        ? widget.entries.length * widget.repeatCount + widget.initialPage
        : widget.initialPage;

    controller = PageController(
      initialPage: initialPage,
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      scrollDirection: widget.scrollDirection,
      scrollBehavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        overscroll: false,
      ),
      onPageChanged: (page) {
        final realPage = calculateEffectiveIndex(page);
        widget.onPageChanged?.call(realPage);
        print('current page: $realPage');
      },
      padEnds: true,
      pageSnapping: true,
      itemCount: widget.infiniteScroll ? null : widget.entries.length,
      itemBuilder: (_, index) {
        final effectiveIndex = calculateEffectiveIndex(index);

        return AnimatedBuilder(
          animation: controller,
          child: _buildConstrainedWidget(effectiveIndex),
          builder: (__, child) {
            final position = controller.position;

            final int currentPage =
                !position.hasPixels || position.hasContentDimensions
                    ? controller.page!.round()
                    : controller.initialPage;
            final int realPage = calculateEffectiveIndex(currentPage);

            if (widget.enlargeCenter) {
              final scale = realPage == effectiveIndex
                  ? widget.centerScale
                  : widget.sideScale;

              return AnimatedScale(
                scale: scale,
                duration: const Duration(
                  milliseconds: 200,
                ),
                child: child,
              );
            } else {
              return child!;
            }
          },
        );
      },
    );
  }

  Widget _buildConstrainedWidget(int index) {
    final child = widget.entries[index].builder();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = widget.aspectRatio != null
            ? width / widget.aspectRatio!
            : constraints.maxHeight;

        late BoxConstraints specificConstraints;

        switch (widget.constraintStrategy) {
          case EntryConstraintStrategy.loosen:
            specificConstraints = BoxConstraints(
              maxWidth: width,
              maxHeight: height,
            );
            break;
          case EntryConstraintStrategy.tight:
            specificConstraints =
                BoxConstraints.tightFor(width: width, height: height);
            break;
        }
        print('constrains: $specificConstraints');

        return Align(
          child: ConstrainedBox(
            constraints: specificConstraints.enforce(constraints.loosen()),
            child: child,
          ),
        );
      },
    );
  }

  int calculateEffectiveIndex(int index) {
    final fixedLength = widget.entries.length;
    return index % fixedLength;
  }
}
