import 'dart:math';
import 'dart:ui';

import 'package:flutter_tips/sphere/helper.dart';
import 'package:vector_math/vector_math_64.dart';

class Radians {
  final double phi;
  final double theta;

  const Radians({
    required this.phi,
    required this.theta,
  });
}

class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({
    required this.latitude,
    required this.longitude,
  });

  // get radians refer to x-axis up
  /// x-yz
  Radians get radians => Radians(
        phi: (90 + longitude) * pi / 180,
        theta: (90 - latitude) * pi / 180,
      );

  // get radians refer to y-axis up
  // y-zx
  Radians get radiansYAxisUp => Radians(
        phi: (90 - longitude) * pi / 180,
        theta: (latitude) * pi / 180,
      );

  // get radians refer to z-axis up
  // z-xy
  Radians get radiansZAxisUp => Radians(
        phi: latitude * pi / 180,
        theta: longitude * pi / 180,
      );

  @override
  String toString() {
    return 'Coordinates{latitude: $latitude, longitude: $longitude}';
  }

  Vector3 toXYPlane(double radius) {
    final phi = latitude * pi / 180;
    final theta = longitude * pi / 180;

    final x = radius * cos(phi) * cos(theta);
    final y = radius * cos(phi) * sin(theta);
    final z = radius * sin(phi);

    return Vector3(x, y, z);
  }

  Vector3 toZXPlane(double radius, {bool flip = false}) {
    final phi = latitude * pi / 180;
    final theta = longitude * pi / 180;

    final x = radius * cos(phi) * cos(theta);
    final y = radius * sin(phi) * (flip ? -1 : 1);
    final z = radius * cos(phi) * sin(theta);

    return Vector3(x, y, z);
  }

  Vector3 toYZPlane(double radius) {
    final phi = latitude * pi / 180;
    final theta = longitude * pi / 180;

    final x = radius * sin(phi);
    final y = radius * cos(phi) * cos(theta);
    final z = radius * cos(phi) * sin(theta);

    return Vector3(x, y, z);
  }
}

class Rotation {
  final double x;
  final double y;
  final double z;

  const Rotation({
    this.x = 0,
    this.y = 0,
    this.z = 0,
  });

  Rotation copyWith({
    double? x,
    double? y,
    double? z,
  }) {
    return Rotation(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
    );
  }

  Matrix4 get transform {
    return Matrix4.identity()
      ..rotateX(x)
      ..rotateY(y)
      ..rotateZ(z);
  }
}

class SpherePoint {
  final Coordinates coordinates;
  final Vector3 _vector3;

  double _radius;

  SpherePoint(this.coordinates, double radius)
      : _radius = radius,
        _vector3 = coordinates.toZXPlane(radius, flip: false);

  Matrix4 rotate(Rotation rotation) {
    final rotMatrix = rotation.transform;

    final transformed = rotMatrix.transform3(_vector3);

    return Matrix4.translationValues(
        transformed.x, transformed.y, transformed.z);
  }

  Offset rotateOffset(Rotation rotation) {
    final offset = SphereMath.geolocationToOffset(coordinates,
        radius: _radius, rotation: rotation);

    return offset;
  }

  Offset get offset {
    return Offset(_vector3.x, _vector3.y);
  }
}
