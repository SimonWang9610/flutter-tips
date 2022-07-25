import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/planet/models.dart';

class CloudPlanet extends StatefulWidget {
  final List<PlanetItem> items;
  final double minRadius;
  final Duration velocity;
  const CloudPlanet({
    Key? key,
    required this.items,
    this.minRadius = 50,
    this.velocity = const Duration(
      seconds: 1,
    ),
  }) : super(key: key);

  @override
  State<CloudPlanet> createState() => _CloudPlanetState();
}

class _CloudPlanetState extends State<CloudPlanet>
    with SingleTickerProviderStateMixin {
  late final AnimationController velocityController;
  late final PlanetData data;

  Offset _velocityPerSecond = Offset.zero;

  @override
  void initState() {
    super.initState();

    data = PlanetData(items: widget.items);
    velocityController = AnimationController(
      vsync: this,
      duration: widget.velocity,
    );
  }

  @override
  void dispose() {
    data.dispose();
    velocityController.dispose();
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
        onPanUpdate: (details) {
          final delta = details.delta;
          data.updateCoordinateForItems(delta);
        },
        onPanEnd: _onPanEnd,
        child: SizedBox.square(
          dimension: data.effectiveRadius * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final item in data.items) item.widget,
            ],
          ),
        ),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    velocityController.reset();

    velocityController.addListener(_decreasingVelocityByTick);

    velocityController.forward().then(
          (_) => velocityController.removeListener(_decreasingVelocityByTick),
        );
  }

  void _decreasingVelocityByTick() {
    final delta =
        Offset.lerp(_velocityPerSecond, Offset.zero, velocityController.value);
    data.updateCoordinateForItems(delta!);
  }
}
