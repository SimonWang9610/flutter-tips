import 'package:flutter/material.dart';
import 'models.dart';

typedef CarouselIndicatorBuilder = Widget Function(CarouselEntryController);

class CarouselSlider extends StatefulWidget {
  final Axis scrollDirection;

  /// the ratio of the current center entry occupying its parent width
  /// (which is typically constrained by its parent's [BoxConstraints] and not the real screen width)
  final double viewportFraction;

  final ValueChanged<int>? onEntryChanged;
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

  /// if [infiniteScroll] is false, [repeatCount] will be ignored
  /// if true, [repeatCount] will be used to set [PageController.initialPage] which will be equal to
  /// [repeatCount] *  the length of [entries]
  /// because the [PageView] always starts scrolling from 0
  /// so we need setting [PageController.initialPage] intentionally to display the previous entry of [initialPage]
  /// visually making [CarouselSlider] infinite scrolling.
  final bool infiniteScroll;
  final int repeatRounds;
  final int initialEntry;
  final CarouselIndicatorBuilder? indicatorBuilder;

  const CarouselSlider({
    Key? key,
    required this.entries,
    this.onEntryChanged,
    this.indicatorBuilder,
    this.viewportFraction = 0.6,
    this.initialEntry = 0,
    this.scrollDirection = Axis.horizontal,
    this.constraintStrategy = EntryConstraintStrategy.tight,
    this.infiniteScroll = true,
    this.enlargeCenter = true,
    this.aspectRatio = 2 / 1,
    this.centerScale = 1.2,
    this.repeatRounds = 100,
  }) : super(key: key);

  @override
  State<CarouselSlider> createState() => CarouselSliderState();
}

class CarouselSliderState extends State<CarouselSlider> {
  late CarouselEntryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CarouselEntryController(
      entries: widget.entries,
      infiniteScroll: widget.infiniteScroll,
      repeatRounds: widget.repeatRounds,
      initialEntry: widget.initialEntry,
      viewportFraction: widget.viewportFraction,
      onEntryChanged: widget.onEntryChanged,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CarouselSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller.pageController,
            scrollDirection: widget.scrollDirection,
            scrollBehavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              overscroll: false,
            ),
            onPageChanged: _controller.onPageChanged,
            padEnds: true,
            pageSnapping: true,
            itemCount: widget.infiniteScroll ? null : widget.entries.length,
            itemBuilder: (_, index) {
              final entryIndex = _controller.toEntry(index);

              print("index: $index, entry: $entryIndex");

              return AnimatedBuilder(
                animation: _controller.pageController,
                child: _buildConstrainedWidget(entryIndex),
                builder: (__, child) {
                  final currentEntry = _controller.currentEntry.value;

                  if (widget.enlargeCenter) {
                    final scale = currentEntry == entryIndex
                        ? widget.centerScale
                        : 2 - widget.centerScale;

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
          ),
        ),
        if (widget.indicatorBuilder != null)
          Center(
            child: SizedBox(
              height: 30,
              width: 100,
              child: widget.indicatorBuilder!(_controller),
            ),
          ),
      ],
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

        return Align(
          child: ConstrainedBox(
            constraints: specificConstraints.enforce(constraints.loosen()),
            child: child,
          ),
        );
      },
    );
  }
}

class DefaultCarouselIndicator extends StatefulWidget {
  final CarouselEntryController carouselEntryController;
  final Axis scrollDirection;
  final double separatedSize;
  final double indicatorSize;
  const DefaultCarouselIndicator({
    Key? key,
    required this.carouselEntryController,
    this.indicatorSize = 24,
    this.separatedSize = 8,
    this.scrollDirection = Axis.horizontal,
  }) : super(key: key);

  @override
  State<DefaultCarouselIndicator> createState() =>
      _DefaultCarouselIndicatorState();
}

class _DefaultCarouselIndicatorState extends State<DefaultCarouselIndicator> {
  late final ScrollController controller;
  @override
  void initState() {
    super.initState();

    final currentEntry = widget.carouselEntryController.currentEntry.value;

    controller = ScrollController(
      initialScrollOffset:
          currentEntry * (widget.indicatorSize + widget.separatedSize),
    );

    widget.carouselEntryController.currentEntry.addListener(_handlePageChanged);
  }

  @override
  void dispose() {
    widget.carouselEntryController.currentEntry
        .removeListener(_handlePageChanged);
    controller.dispose();
    super.dispose();
  }

  void _handlePageChanged() {
    print("page changed");

    final currentEntry = widget.carouselEntryController.currentEntry.value;
    final offset = currentEntry * (widget.indicatorSize + widget.separatedSize);

    controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInCirc,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      physics: const ClampingScrollPhysics(),
      scrollDirection: widget.scrollDirection,
      itemCount: widget.carouselEntryController.totalEntry,
      separatorBuilder: (context, index) {
        if (widget.scrollDirection == Axis.horizontal) {
          return SizedBox(width: widget.separatedSize);
        } else {
          return SizedBox(height: widget.separatedSize);
        }
      },
      itemBuilder: (_, index) {
        return ValueListenableBuilder<int>(
          valueListenable: widget.carouselEntryController.currentEntry,
          builder: (context, currentEntry, child) {
            final scale = currentEntry == index ? 1.2 : 0.8;
            return CircleIndicator(
              entryId: index,
              scale: scale,
              label: "${index + 1}",
              dimension: widget.indicatorSize,
              jumpTo: widget.carouselEntryController.jumpToEntry,
              animateTo: widget.carouselEntryController.animateToEntry,
            );
          },
        );
      },
    );
  }
}

typedef AnimateToEntryCallback = Future<void> Function(int,
    {required Duration duration, required Curve curve});

typedef JumpToEntryCallback = void Function(int);

class CircleIndicator extends StatelessWidget {
  final int entryId;
  final String? label;
  final double scale;
  final Duration duration;
  final double dimension;
  final AnimateToEntryCallback? animateTo;
  final JumpToEntryCallback? jumpTo;
  const CircleIndicator({
    Key? key,
    required this.entryId,
    this.animateTo,
    this.jumpTo,
    this.label,
    this.scale = 1.0,
    this.dimension = 24,
    this.duration = const Duration(milliseconds: 100),
  })  : assert(jumpTo != null || animateTo != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: scale,
      duration: duration,
      child: GestureDetector(
        onTap: () {
          if (animateTo != null) {
            animateTo!(
              entryId,
              duration: duration,
              curve: Curves.bounceIn,
            );
          } else {
            jumpTo!(entryId);
          }
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(),
            shape: BoxShape.circle,
            color: scale > 1.0 ? Colors.greenAccent : null,
          ),
          child: SizedBox.square(
            dimension: dimension,
            child: label != null
                ? Center(
                    child: Text(label!),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
