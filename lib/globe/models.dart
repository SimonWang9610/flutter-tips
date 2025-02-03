import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

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

  Rotation operator +(Rotation other) {
    return Rotation(
      x: x + other.x,
      y: y + other.y,
      z: z + other.z,
    );
  }
}

class Geolocation {
  final String? name;
  final double latitude;
  final double longitude;

  Geolocation({
    this.name,
    required this.latitude,
    required this.longitude,
  });

  Vector3 toCartesianPoint(double radius) {
    // Convert to radians and adjust angles to match shader
    final phi = (90 - latitude) * pi / 180;
    final theta = (longitude + 180) * pi / 180;

    final v = Vector3(
      -radius * sin(phi) * cos(theta),
      radius * cos(phi),
      radius * sin(phi) * sin(theta),
    );
    // return v;
    return Geolocation.rotate(v, const Rotation(y: -pi / 2, x: pi));
  }

  Vector3 toCartesianZXPlane(double radius) {
    final phi = latitude * pi / 180;
    final theta = longitude * pi / 180;

    final v = Vector3(
      radius * cos(phi) * sin(theta),
      radius * sin(phi),
      radius * cos(phi) * cos(theta),
    );

    return Geolocation.rotate(v, const Rotation(y: 0, x: pi));
  }

  Vector3 toCartesianYZPlane(double radius) {
    final phi = latitude * pi / 180;
    final theta = longitude * pi / 180;

    final v = Vector3(
      radius * sin(phi),
      radius * cos(phi) * cos(theta),
      radius * cos(phi) * sin(theta),
    );

    return Geolocation.rotate(v, const Rotation(z: -pi / 2, x: -pi / 2));
  }

  Vector3 toCartesianXYPlane(double radius) {
    final phi = latitude * pi / 180;
    final theta = longitude * pi / 180;

    final v = Vector3(
      radius * cos(phi) * cos(theta),
      radius * cos(phi) * sin(theta),
      radius * sin(phi),
    );

    return Geolocation.rotate(v, const Rotation(x: pi / 2, y: -pi / 2));
  }

  Offset to2DPixel(Size size) {
    final latRad = latitude.clamp(-85.0511, 85.0511) * pi / 180;

    // Mercator projection formula
    final x = (longitude + 180) * (size.width / 360);
    final y = (size.height / 2) -
        (size.width * log(tan(pi / 4 + latRad / 2)) / (2 * pi));

    return Offset(x, y);
  }

  static Vector3 rotate(Vector3 p, Rotation rot) {
    // adjust to z-XY plane
    // calculated by the equator/north/south poles
    // rot += const Rotation(y: -pi / 2, x: pi / 2);
    // // Match shader rotation order
    // final cosY = cos(rot.y);
    // final sinY = sin(rot.y);
    // final x2 = p.x * cosY - p.z * sinY;
    // final z2 = p.x * sinY + p.z * cosY;

    // final cosX = cos(rot.x);
    // final sinX = sin(rot.x);
    // final y3 = p.y * cosX - z2 * sinX;
    // final z3 = p.y * sinX + z2 * cosX;

    // return Vector3(x2, y3, z3);
    final y2 = p.y * cos(rot.x) - p.z * sin(rot.x);
    final z2 = p.y * sin(rot.x) + p.z * cos(rot.x);
    final x2 = p.x * cos(rot.y) - z2 * sin(rot.y);
    final z3 = p.x * sin(rot.y) + z2 * cos(rot.y);

    final x3 = x2 * cos(rot.z) - y2 * sin(rot.z);
    final y3 = x2 * sin(rot.z) + y2 * cos(rot.z);

    return Vector3(x3, y3, z3);
  }

  /// [p] is a normalized point on the screen
  static Offset asSpherePoint(Offset o, Rotation rot) {
    final x = (o.dx - 0.5) * 2;
    final y = (o.dy - 0.5) * 2;
    final z = sqrt(1 - x * x - y * y);

    final p = rotate(Vector3(x, y, z), rot);

    final u = atan2(p.x, p.z) / pi + 0.5;
    final v = asin(p.y) / pi + 0.5;

    return Offset(u, v);
  }
}

class TextureShader {
  static Future<ui.FragmentProgram> fromAsset(String path) async {
    final data = await ui.FragmentProgram.fromAsset(path);
    return data;
  }

  static Future<ui.Image> fromAssetImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  final String image;
  final String shaderPath;

  TextureShader({
    required this.image,
    required this.shaderPath,
  });

  ui.FragmentProgram? frag;
  ui.Image? texture;

  Future<void> load() async {
    texture ??= await TextureShader.fromAssetImage(image);
    frag ??= await TextureShader.fromAsset(shaderPath);
  }

  ui.FragmentShader? get shader => frag?.fragmentShader();
}
