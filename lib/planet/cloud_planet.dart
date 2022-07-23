import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/planet/models.dart';

class CloudPlanet extends StatefulWidget {
  final List<PlanetItem> items;
  final double minRadius;
  const CloudPlanet({
    Key? key,
    required this.items,
    this.minRadius = 50,
  }) : super(key: key);

  @override
  State<CloudPlanet> createState() => _CloudPlanetState();
}

class _CloudPlanetState extends State<CloudPlanet> {
  late final PlanetData data;

  @override
  void initState() {
    super.initState();

    data = PlanetData(items: widget.items);
  }

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final radius = min(constraints.maxWidth, constraints.maxHeight) / 2;

      if (radius < widget.minRadius) {
        return const SizedBox.shrink();
      }

      data.setRadius(radius);

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: SizedBox.square(
          dimension: data.effectiveRadius * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final item in data.items) item.widget,
            ],
          ),
        ),
        onPanUpdate: (details) {
          final delta = details.delta;
          data.updateCoordinateForItems(delta);
        },
      );
    });
  }
}
