import 'dart:math' as math;
import 'package:flutter/material.dart';

class GeoPoint {
  final double latitude;
  final double longitude;
  final Color color;
  final double radius;

  GeoPoint({
    required this.latitude,
    required this.longitude,
    this.color = Colors.red,
    this.radius = 5.0,
  });
}

class WorldMapWidget extends StatefulWidget {
  const WorldMapWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<WorldMapWidget> createState() => _WorldMapWidgetState();
}

class _WorldMapWidgetState extends State<WorldMapWidget> {
  double _width = 600;
  double _height = 400;

  // locations: london, new york, tokyo, toronto
  final points = [
    GeoPoint(
      latitude: 51.5074,
      longitude: -0.1278,
      color: Colors.blue,
      radius: 8,
    ), // London
    GeoPoint(
      latitude: 40.7128,
      longitude: -74.0060,
      color: Colors.red,
      radius: 8,
    ), // New York
    GeoPoint(
      latitude: 35.6895,
      longitude: 139.6917,
      color: Colors.green,
      radius: 8,
    ), // Tokyo
    GeoPoint(
      latitude: 43.6532,
      longitude: -79.3832,
      color: Colors.yellow,
      radius: 8,
    ), // Toronto
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background map image
          Image.asset(
            "assets/earth-day.jpg",
            width: _width,
            height: _height,
            fit: BoxFit.fill,
          ),
          // Custom painter for points
          CustomPaint(
            size: Size(_width, _height),
            painter: MapPointsPainter(points: points),
          ),
        ],
      ),
    );
  }
}

class MapPointsPainter extends CustomPainter {
  final List<GeoPoint> points;

  MapPointsPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (var point in points) {
      final screenPoint = _convertGeoToPixel(
        point.latitude,
        point.longitude,
        size.width,
        size.height,
      );

      final paint = Paint()
        ..color = point.color
        ..style = PaintingStyle.fill;

      // Draw point
      canvas.drawCircle(screenPoint, point.radius, paint);
    }
  }

  @override
  bool shouldRepaint(MapPointsPainter oldDelegate) {
    return oldDelegate.points != points;
  }

  // Convert geographical coordinates to pixel coordinates using Mercator projection
  Offset _convertGeoToPixel(
    double latitude,
    double longitude,
    double mapWidth,
    double mapHeight,
  ) {
    // Clamp latitude to avoid infinite values near poles
    latitude = latitude.clamp(-85.0511, 85.0511);

    // Convert to radians
    final latRad = _toRadians(latitude);

    // Mercator projection formula
    final x = (longitude + 180) * (mapWidth / 360);
    final y = (mapHeight / 2) -
        (mapWidth *
            math.log(math.tan(math.pi / 4 + latRad / 2)) /
            (2 * math.pi));

    return Offset(x, y);
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
