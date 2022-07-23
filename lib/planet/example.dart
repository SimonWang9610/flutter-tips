import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tips/planet/cloud_planet.dart';
import 'package:flutter_tips/planet/models.dart';

class CloudPlanetExample extends StatefulWidget {
  const CloudPlanetExample({Key? key}) : super(key: key);

  @override
  State<CloudPlanetExample> createState() => _CloudPlanetExampleState();
}

class _CloudPlanetExampleState extends State<CloudPlanetExample> {
  final List<PlanetItem> items = List.generate(
    20,
    (index) => PlanetItem(
      index: index,
      builder: () => GestureDetector(
        child: Card(
          color: Colors.primaries[index % Colors.primaries.length],
          shape: const CircleBorder(),
          child: Text('$index'),
        ),
        onTap: () {
          print('tap on $index');
        },
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Planet Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: CloudPlanet(
                  items: items,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
