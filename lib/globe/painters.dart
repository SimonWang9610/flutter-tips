import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

import "dart:ui" as ui;
import 'models.dart';

class GeolocationPainter extends CustomPainter {
  final List<Geolocation> locations;
  final Rotation rotation;

  GeolocationPainter(
    this.locations, {
    required this.rotation,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final paint = Paint()
      ..color = const Color(0xFF00FF00)
      ..strokeWidth = 2;

    final greyPaint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 2;

    for (final location in locations) {
      final pos = location.toCartesianPoint(radius);
      final transformed = Geolocation.rotate(pos, rotation);

      final screenPos = Offset(
        center.dx + transformed.x,
        center.dy + transformed.y,
      );

      final visible = transformed.z < 0;

      canvas.drawCircle(screenPos, 5, visible ? paint : greyPaint);
    }
  }
}

class SingleGeolocationPainter extends CustomPainter {
  final Geolocation location;
  final Rotation rotation;

  SingleGeolocationPainter(
    this.location, {
    required this.rotation,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final paint = Paint()
      ..color = const Color(0xFF00FF00)
      ..strokeWidth = 2;

    final greyPaint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 2;

    final pos = location.toCartesianXYPlane(radius);
    final transformed = Geolocation.rotate(pos, rotation);

    final screenPos = Offset(
      center.dx + transformed.x,
      center.dy + transformed.y,
    );

    final np = screenPos / (2 * radius);
    final uv = Geolocation.asSpherePoint(np, rotation);

    final visible = transformed.z < 0;
    print(
        "location: ${location.name}, screenPos: $screenPos, np: $np, uv: $uv");

    canvas.drawCircle(screenPos, 5, visible ? paint : greyPaint);

    final text = TextPainter(
      text: TextSpan(
        text: location.name,
        style: const TextStyle(
          color: Color(0xFF00FF00),
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    text.paint(
      canvas,
      Offset(
        screenPos.dx + 10,
        screenPos.dy - 10,
      ),
    );
  }
}

class SphereImageTexturePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final Rotation rotation;
  final ui.Image texture;
  final double scale;

  SphereImageTexturePainter(
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

    final imageRatio = texture.width / texture.height;
    final screenRatio = size.width / size.height;

    print("imageRatio: $imageRatio, screenRatio: $screenRatio, scale: $scale");

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

class SphereGridPainter extends CustomPainter {
  final Rotation rotation;
  final int latitudeGap;
  final int longitudeGap;

  SphereGridPainter({
    required this.rotation,
    this.latitudeGap = 60,
    this.longitudeGap = 60,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    for (int lat = 0; lat < latitudeGap; lat++) {
      for (int lon = 0; lon < longitudeGap; lon++) {
        final phi1 = lat * pi / latitudeGap;
        final phi2 = (lat + 1) * pi / latitudeGap;
        final theta1 = lon * 2 * pi / longitudeGap;
        final theta2 = (lon + 1) * 2 * pi / longitudeGap;

        final vertices = [
          _sphericalToCartesian(phi1, theta1, radius),
          _sphericalToCartesian(phi2, theta1, radius),
          _sphericalToCartesian(phi2, theta2, radius),
          _sphericalToCartesian(phi1, theta2, radius),
        ];

        final transformedVertices =
            vertices.map((v) => Geolocation.rotate(v, rotation)).toList();

        // Only draw if at least one vertex is visible
        if (transformedVertices.any((v) => v.z > 0)) {
          final points = transformedVertices
              .map((v) => Offset(
                    center.dx + v.x,
                    center.dy + v.y,
                  ))
              .toList();

          // Draw textured quad
          final paint = Paint();
          final path = Path()
            ..moveTo(points[0].dx, points[0].dy)
            ..lineTo(points[1].dx, points[1].dy)
            ..lineTo(points[2].dx, points[2].dy)
            ..lineTo(points[3].dx, points[3].dy)
            ..close();

          canvas.saveLayer(null, paint);

          paint.color = Color(0xFFCCCCCC);

          canvas.drawPath(path, paint);
          canvas.restore();
        }
      }
    }

    // paint x/y/z axis
    final x = Geolocation.rotate(Vector3(radius, 0, 0), rotation);
    final y = Geolocation.rotate(Vector3(0, radius, 0), rotation);
    final z = Geolocation.rotate(Vector3(0, 0, radius), rotation);

    final xPaint = Paint()..color = const Color(0xFFFF0000);
    final yPaint = Paint()..color = const Color(0xFF00FF00);
    final zPaint = Paint()..color = const Color(0xFF0000FF);

    canvas.drawLine(
      center,
      Offset(center.dx + x.x, center.dy + x.y),
      xPaint,
    );
    // paint label

    canvas.drawLine(
      center,
      Offset(center.dx + y.x, center.dy + y.y),
      yPaint,
    );

    canvas.drawLine(
      center,
      Offset(center.dx + z.x, center.dy + z.y),
      zPaint,
    );
  }

  Vector3 _sphericalToCartesian(double phi, double theta, double radius) {
    return Vector3(
      radius * sin(phi) * cos(theta),
      radius * cos(phi),
      radius * sin(phi) * sin(theta),
    );
  }
}
