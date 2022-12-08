import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef CarouselEntryBuilder = Widget Function();

class CarouselEntry {
  final CarouselEntryBuilder builder;

  CarouselEntry({
    required this.builder,
  });
}

enum EntryConstraintStrategy {
  tight,
  loosen,
}

// TODO: enable updating properties when didUpdateWidget for [CarouselSlider]
class CarouselEntryController with CarouselEntryIndicatorMixin, ChangeNotifier {
  static int pageToEntry(int totalEntry, int page) => page % totalEntry;

  final List<CarouselEntry> entries;
  final int initialEntry;

  /// if [infiniteScroll] is false, [repeatCount] will be ignored
  /// if true, [repeatCount] will be used to set [PageController.initialPage] which will be equal to
  /// [repeatCount] *  the length of [entries]
  /// because the [PageView] always starts scrolling from 0
  /// so we need setting [PageController.initialPage] intentionally to display the previous entry of [initialPage]
  /// visually making [CarouselSlider] infinite scrolling.

  final bool infiniteScroll;
  final int repeatRounds;
  final double viewportFraction;
  final ValueChanged<int>? onEntryChanged;
  late final PageController _controller;

  CarouselEntryController({
    required this.entries,
    this.infiniteScroll = true,
    this.repeatRounds = 400,
    this.initialEntry = 0,
    this.viewportFraction = 0.6,
    this.onEntryChanged,
  }) {
    _currentEntry = initialEntry;
    _currentPage = initialPage;
    _controller = PageController(
      initialPage: _currentPage,
      viewportFraction: viewportFraction,
    );
  }

  int get initialPage => infiniteScroll
      ? entries.length * repeatRounds + initialEntry
      : initialEntry;

  @override
  int get totalEntry => entries.length;

  @override
  PageController get pageController => _controller;

  void onPageChanged(int page) {
    _currentPage = page;
    _currentEntry = CarouselEntryController.pageToEntry(totalEntry, page);
    currentEntry.value = _currentEntry;
  }

  int toEntry(int page) =>
      CarouselEntryController.pageToEntry(totalEntry, page);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

mixin CarouselEntryIndicatorMixin {
  // final position = _controller.position;
  // final int currentPage = !position.hasPixels || position.hasContentDimensions
  //     ? _controller.page!.round()
  //     : _controller.initialPage;
  // return toEntry(currentPage);

  late final ValueNotifier<int> currentEntry =
      ValueNotifier<int>(_currentEntry);

  late int _currentPage;
  late int _currentEntry;

  PageController get pageController;
  int get totalEntry;

  Future<void> animateToEntry(int entry,
      {required Duration duration, required Curve curve}) async {
    final page = _currentPage + (entry - _currentEntry);
    pageController.animateToPage(page, duration: duration, curve: curve);
  }

  void jumpToEntry(int entry) {
    final page = _currentPage + (entry - _currentEntry);

    pageController.jumpToPage(page);
  }

  Future<void> nextEntry({required Duration duration, required Curve curve}) {
    return animateToEntry((_currentEntry + 1) % totalEntry,
        duration: duration, curve: curve);
  }

  Future<void> previousEntry(
      {required Duration duration, required Curve curve}) {
    return animateToEntry((_currentEntry - 1) % totalEntry,
        duration: duration, curve: curve);
  }
}
