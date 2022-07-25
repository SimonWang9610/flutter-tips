import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector4;

typedef PlanetItemBuilder = Widget Function();

abstract class PlanetValueNotifier {
  final int initValue;
  final int _divisor;
  late final ValueNotifier<bool> _notifier;

  PlanetValueNotifier(this.initValue)
      : _divisor = (initValue + 1) * 2,
        _notifier = ValueNotifier(initValue.isEven);

  ValueNotifier<bool> get notifier => _notifier;

  /// avoid [notifier.value] incrementing without restrictions;
  void notifyListener() {
    // _notifier.value = (_notifier.value + 1) % _divisor;
    // if (initValue == 0) {
    //   print('notifier value: ${_notifier.value}');
    // }
    _notifier.value = !_notifier.value;
  }

  void dispose() {
    _notifier.dispose();
  }
}

class PlanetItem extends PlanetValueNotifier {
  final int index;
  final PlanetItemBuilder builder;
  final Vector4 vector;

  late final SphericalAngle angles;
  double radius;

  PlanetItem({
    required this.builder,
    required this.index,
  })  : vector = Vector4.zero(),
        radius = 0.0,
        super(index);

  /// the spherical coordinate:
  /// x = r * sin(phi) * cos(theta)
  /// y = r * sin(phi) * sin(theta)
  /// z = r * cos(phi)
  void initialize({
    required SphericalAngle angles,
    required double effectiveRadius,
  }) {
    radius = effectiveRadius;
    angles = angles;

    final x = radius * cos(angles.theta) * sin(angles.phi);
    final y = radius * sin(angles.theta) * sin(angles.phi);
    final z = radius * cos(angles.phi);

    vector.setValues(x, y, z, 1);
  }

  Matrix4 get transform {
    // distribute the item evenly along the z-axis
    final factor = 1 / (1 + vector.z / (2 * radius));

    return Matrix4.identity()..translate(vector * factor);
  }

  double get scale => 1.5 + vector.z / radius;

  Widget get widget {
    return ValueListenableBuilder(
      valueListenable: notifier,
      child: builder(),
      builder: (_, __, child) {
        return Transform(
          transform: transform,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(
              milliseconds: 150,
            ),
            child: child,
          ),
        );
        // return AnimatedTransform(
        //   transform: transform,
        //   child: child,
        // );
      },
    );
  }

  void applyTransform(Matrix4 transform) {
    vector.applyMatrix4(transform);
    notifyListener();
  }

  /// when the [PlanetData.effectiveRadius] changes
  ///  all [PlanetItem] should also resize
  void resizeRadius(double newRadius) {
    final scale = newRadius / radius;
    vector.multiply(Vector4(scale, scale, scale, 1));
    radius = newRadius;
    notifyListener();
  }
}

class PlanetData {
  final List<PlanetItem> items;
  final RotationAngles rotationAngles;

  double effectiveRadius;
  bool initialized;

  PlanetData({
    required this.items,
    double speed = 1.0,
    double factor = 0.5,
  })  : effectiveRadius = 0.0,
        rotationAngles = RotationAngles.init(speed: speed, factor: factor),
        initialized = false;

  void setRadius(double value) {
    if (!initialized || effectiveRadius == 0.0 || value != effectiveRadius) {
      effectiveRadius = value;
      setCoordinateForItems();
      initialized = true;
    }
    // print('effective radius: $effectiveRadius');
  }

  void setCoordinateForItems() {
    final count = items.length;

    for (int i = 1; i < count + 1; i++) {
      if (initialized) {
        items[i - 1].resizeRadius(effectiveRadius);
      } else {
        items[i - 1].initialize(
          angles: SphericalAngle.index(i, count),
          // angles: SphericalAngle.random(),
          effectiveRadius: effectiveRadius,
        );
      }
    }

    if (!initialized) {
      items.sort(
        (previous, current) => current.vector.z.compareTo(previous.vector.z),
      );
    }
  }

  void updateCoordinateForItems(Offset delta) {
    /// if [xAngle] is negative sign, the rotation will follow the direction of the gesture
    /// otherwise, it will be the opposite direction of the gesture
    final double xAngle = -delta.dy / effectiveRadius * pi;
    final double yAngle = delta.dx / effectiveRadius * pi;

    final double zAngle = delta.distance / effectiveRadius * pi;

    if (zAngle == 0) return;

    rotationAngles.update(x: xAngle, y: yAngle, z: zAngle);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      final transformations = Matrix4.rotationX(rotationAngles.xAngle) *
          Matrix4.rotationY(rotationAngles.yAngle) *
          Matrix4.rotationZ(rotationAngles.zAngle);

      // item.vector.applyMatrix4(transformations);
      item.applyTransform(transformations);
    }
  }

  void dispose() {
    for (final item in items) {
      item.dispose();
    }
  }
}

/// arguments used to convert the Cartesian coordinate to spherical coordinate
class SphericalAngle {
  final double phi;
  final double theta;

  SphericalAngle({
    required this.phi,
    required this.theta,
  });

  SphericalAngle copyWith({double? theta, double? phi}) {
    return SphericalAngle(
      phi: phi ?? this.phi,
      theta: theta ?? this.theta,
    );
  }

  SphericalAngle add({double thetaDelta = 0.0, double phiDelta = 0.0}) {
    return SphericalAngle(phi: phi + phiDelta, theta: theta + thetaDelta);
  }

  factory SphericalAngle.zero() => SphericalAngle(phi: 0, theta: 0);

  factory SphericalAngle.index(int index, int total) {
    final phi = acos(-1.0 + (2.0 * index - 1.0) / total);
    final theta = sqrt(total * pi) * phi;

    return SphericalAngle(phi: phi, theta: theta);
  }

  factory SphericalAngle.random() {
    return SphericalAngle(
        phi: Random().nextDouble() * pi, theta: Random().nextDouble() * 2 * pi);
  }
}

/// store the current rotation angles for x-, y-, z- axis
class RotationAngles {
  final double factor;
  final double speed;
  double xAngle;
  double yAngle;
  double zAngle;

  RotationAngles({
    required this.xAngle,
    required this.yAngle,
    required this.zAngle,
    required this.factor,
    required this.speed,
  });

  factory RotationAngles.init({double? speed, double? factor}) =>
      RotationAngles(
        xAngle: 0.0,
        yAngle: 0.0,
        zAngle: 0.0,
        speed: speed ?? 1,
        factor: factor ?? 1,
      );

  void update({double? x, double? y, double? z}) {
    xAngle = x ?? 0.0;
    yAngle = y ?? 0.0;
    zAngle = z ?? 0.0;
    applyFactor();
  }

  void applyFactor() {
    xAngle *= factor * speed;
    yAngle *= factor * speed;
    zAngle *= factor * speed;
  }
}
