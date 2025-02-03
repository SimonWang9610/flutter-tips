import 'dart:math';
import 'dart:ui';

import 'package:flutter_tips/planet/helper.dart';
import 'package:flutter_tips/sphere/models.dart';
import 'package:vector_math/vector_math_64.dart';

class SphereMath {
  static Offset mapCoordinatesToOffset(
    Coordinates coordinates, {
    required Size size,
    required double rotation,
    double zoom = 1.0,
    double depthFactor = 0.5,
  }) {
    final phi = coordinates.latitude * pi / 180;
    final theta = coordinates.longitude * pi / 180;

    final x = cos(phi) * cos(theta);
    final y = sin(phi);
    final z = cos(phi) * sin(theta);

    final r = size.shortestSide / 2;

    final xRot = x * cos(rotation) - z * sin(rotation);
    final zRot = x * sin(rotation) + z * cos(rotation);

    final screenX = xRot / (1 - zRot * depthFactor);
    final screenY = y / (1 - zRot * depthFactor);

    // final center = size.center(Offset.zero);
    final center = Offset.zero;

    return Offset(
      center.dx + screenX * r * zoom,
      center.dy + screenY * r * zoom,
    );
  }

  static Vector3 coordinatesToVector3(Coordinates coordinates, double radius) {
    final phi = coordinates.latitude * pi / 180;
    final theta = coordinates.longitude * pi / 180;

    final x = radius * cos(phi) * cos(theta);
    final y = radius * cos(phi) * sin(theta);
    final z = radius * sin(phi);

    return Vector3(z, x, -y);
  }

  static Offset geolocationToOffset(
    Coordinates coordinates, {
    required double radius,
    required Rotation rotation,
  }) {
    final u = coordinates.longitude * pi / 180 - pi / 2;
    final v = coordinates.latitude * pi / 180 - pi / 2;

    final x = cos(v) * cos(u);
    final y = sin(v);
    final z = cos(v) * sin(u);

    final x2 = x * cos(rotation.z) - y * sin(rotation.z);
    final y2 = -x * sin(rotation.z) + y * cos(rotation.z);
    final x3 = x2 * cos(rotation.y) + z * sin(rotation.y);
    final z2 = -x2 * sin(rotation.y) + z * cos(rotation.y);
    final y3 = y2 * cos(rotation.x) - z2 * sin(rotation.x);
    final z3 = y2 * sin(rotation.x) + z2 * cos(rotation.x);

    return Offset(
          atan(z3 / x3) / pi + 0.5,
          asin(y3) / pi + 0.5,
        ) *
        radius;
  }
}
