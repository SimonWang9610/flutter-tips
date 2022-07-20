import 'package:flutter/material.dart';
import 'package:flutter_tips/carousel/carousel_slider.dart';
import 'package:flutter_tips/carousel/models.dart';

class CarouselSliderExample extends StatefulWidget {
  const CarouselSliderExample({Key? key}) : super(key: key);

  @override
  State<CarouselSliderExample> createState() => _CarouselSliderExampleState();
}

class _CarouselSliderExampleState extends State<CarouselSliderExample> {
  final List<CarouselEntry> entries = [
    CarouselEntry(
      builder: () => Card(
        color: Colors.green,
        child: Text('First'),
      ),
    ),
    CarouselEntry(
      builder: () => Card(
        color: Colors.yellow,
        child: Text('Second'),
      ),
    ),
    CarouselEntry(
      builder: () => Card(
        color: Colors.blue,
        child: Text('Third'),
      ),
    ),
    CarouselEntry(
      builder: () => Card(
        color: Colors.red,
        child: Text('Fourth'),
      ),
    )
  ];

  final GlobalKey<CarouselSliderState> sliderKey =
      GlobalKey<CarouselSliderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carousel Slider Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          children: [
            const Text('Slider'),
            Expanded(
              child: CarouselSlider(
                key: sliderKey,
                entries: entries,
              ),
            )
          ],
        ),
      ),
    );
  }
}
