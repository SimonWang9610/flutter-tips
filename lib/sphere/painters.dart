import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_tips/sphere/helper.dart';
import 'package:flutter_tips/sphere/models.dart';

class SpherePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image texture;
  final double scale;
  final double rotation;

  SpherePainter(
    this.shader, {
    required this.texture,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final xShift = size.width / 2 - radius;
    final yShift = size.height / 2 - radius;

    // print('Size: $size, radius: $radius, xShift: $xShift, yShift: $yShift');

    shader.setFloat(0, radius * 2);
    shader.setFloat(1, radius * 2);
    shader.setFloat(2, rotation);
    shader.setFloat(3, scale);
    shader.setFloat(4, xShift);
    shader.setFloat(5, yShift);
    shader.setImageSampler(0, texture);

    final paint = Paint()..shader = shader;

    // canvas.drawRect(
    //   Rect.fromLTWH(0, 0, size.width, size.height),
    //   paint,
    // );
    canvas.drawPaint(paint);

    canvas.drawPoints(
      ui.PointMode.points,
      [size.center(Offset.zero)],
      Paint()
        ..color = ui.Color.fromARGB(255, 230, 219, 11)
        ..strokeWidth = 10,
    );
  }
}

class SphereLocationPainter extends CustomPainter {
  final List<Coordinates> locations;
  final double rotation;
  final double zoom;

  SphereLocationPainter(
    this.locations, {
    this.rotation = 0.0,
    this.zoom = 1.0,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final effectiveSize = Size(radius * 2, radius * 2);

    final paint = Paint()
      ..color = ui.Color.fromARGB(255, 255, 0, 72)
      ..style = PaintingStyle.fill
      ..strokeWidth = 10;

    final points = locations
        .map((location) => SphereMath.mapCoordinatesToOffset(
              location,
              size: effectiveSize,
              rotation: rotation,
              zoom: zoom,
            ))
        .toList();

    canvas.drawPoints(
      ui.PointMode.points,
      points,
      paint,
    );
  }
}

class SphereRotationPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final Rotation rotation;
  final ui.Image texture;
  final double scale;

  SphereRotationPainter(
    this.shader, {
    required this.rotation,
    required this.texture,
    this.scale = 1.0,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    // final xShift = size.width / 2 - radius;
    // final yShift = size.height / 2 - radius;

    shader.setFloat(0, radius * 2);
    shader.setFloat(1, radius * 2);
    shader.setFloat(2, rotation.x);
    shader.setFloat(3, rotation.y);
    shader.setFloat(4, rotation.z);
    shader.setFloat(5, scale);
    shader.setImageSampler(0, texture);

    final paint = Paint()..shader = shader;

    canvas.drawPaint(paint);
  }
}

class SphereMatrixPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image texture;
  final Matrix4 rotation;

  SphereMatrixPainter(
    this.shader, {
    required this.texture,
    required this.rotation,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;

    shader.setFloat(0, radius * 2);
    shader.setFloat(1, radius * 2);

    for (var i = 0; i < 16; i++) {
      shader.setFloat(i + 2, rotation.storage[i]);
    }

    shader.setImageSampler(0, texture);

    final paint = Paint()..shader = shader;

    canvas.drawPaint(paint);
  }
}
