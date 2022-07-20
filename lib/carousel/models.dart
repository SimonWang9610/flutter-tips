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
