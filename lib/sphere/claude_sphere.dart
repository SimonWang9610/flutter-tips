import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

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

class EarthGlobeWidget extends StatefulWidget {
  final double width;
  final double height;
  const EarthGlobeWidget({
    Key? key,
    this.width = 600,
    this.height = 400,
  }) : super(key: key);

  @override
  State<EarthGlobeWidget> createState() => _EarthGlobeWidgetState();
}

class _EarthGlobeWidgetState extends State<EarthGlobeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Vector3 _rotation = Vector3(0, 0, 0);
  bool _isDragging = false;
  Offset? _lastPosition;

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
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _loadImage("assets/earth-day.jpg", "shaders/sphere_claude.frag");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _lastPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _lastPosition == null) return;

    final delta = details.localPosition - _lastPosition!;
    setState(() {
      _rotation.y += delta.dx * 0.01;
      _rotation.x += delta.dy * 0.01;
      _rotation.x = _rotation.x.clamp(-math.pi / 2, math.pi / 2);
    });
    _lastPosition = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _lastPosition = null;
  }

  ui.Image? _texture;
  ui.FragmentProgram? _frag;

  void _loadImage(String path, String shaderPath) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(Uint8List.view(data.buffer));
    final frame = await codec.getNextFrame();

    _texture = frame.image;

    _frag = await ui.FragmentProgram.fromAsset(shaderPath);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_frag == null || _texture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          // Shader layer
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: EarthShaderPainter(
              shader: _frag!.fragmentShader(),
              earthTexture: _texture!,
              rotation: _rotation,
              time: _controller.value,
            ),
            child: CustomPaint(
              size: Size(widget.width, widget.height),
              painter: GeoPointsPainter(
                points: points,
                rotation: _rotation,
                width: widget.width,
                height: widget.height,
                sphereRadius: 0.8,
              ),
            ),
          ),
          // Points layer
        ],
      ),
    );
  }
}

class EarthShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image earthTexture;
  final Vector3 rotation;
  final double time;

  EarthShaderPainter({
    required this.shader,
    required this.earthTexture,
    required this.rotation,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // final radius = size.shortestSide / 2;
    // // final xShift = size.width / 2 - radius;
    // // final yShift = size.height / 2 - radius;

    // shader.setFloat(0, radius * 2);
    // shader.setFloat(1, radius * 2);
    // shader.setFloat(2, rotation.x);
    // shader.setFloat(3, rotation.y);
    // shader.setFloat(4, rotation.z);
    // shader.setFloat(5, 1);
    // shader.setImageSampler(0, earthTexture);

    // final paint = Paint()..shader = shader;

    // canvas.drawPaint(paint);
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(3, rotation.x);
    shader.setFloat(4, rotation.y);
    // shader.setFloat(5, rotation.z);
    shader.setImageSampler(0, earthTexture);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(EarthShaderPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.rotation != rotation;
  }
}

class GeoPointsPainter extends CustomPainter {
  final List<GeoPoint> points;
  final Vector3 rotation;
  final double width;
  final double height;
  final double sphereRadius;

  GeoPointsPainter({
    required this.points,
    required this.rotation,
    required this.width,
    required this.height,
    required this.sphereRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(width / 2, height / 2);
    final screenRadius = math.min(width, height) * sphereRadius;

    for (final point in points) {
      final pos = _geoToSphere(point.latitude, point.longitude, screenRadius);
      final rotated = _rotatePoint(pos, rotation);

      if (rotated.z > 0) {
        final screenX = center.dx + rotated.x;
        final screenY = center.dy + rotated.y;

        final scale = (rotated.z + screenRadius) / (2 * screenRadius);
        final adjustedRadius = point.radius * scale;

        canvas.drawCircle(
          Offset(screenX, screenY),
          adjustedRadius,
          Paint()
            ..color = point.color.withOpacity(scale)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  Vector3 _geoToSphere(double lat, double lng, double radius) {
    // Convert to radians and adjust angles to match shader
    final phi = (90 - lat) * math.pi / 180;
    final theta = (lng + 180) * math.pi / 180;

    return Vector3(
      -radius * math.sin(phi) * math.cos(theta),
      radius * math.cos(phi),
      radius * math.sin(phi) * math.sin(theta),
    );
  }

  Vector3 _rotatePoint(Vector3 p, Vector3 rot) {
    // Match shader rotation order
    final cosY = math.cos(rot.y);
    final sinY = math.sin(rot.y);
    final x2 = p.x * cosY - p.z * sinY;
    final z2 = p.x * sinY + p.z * cosY;

    final cosX = math.cos(rot.x);
    final sinX = math.sin(rot.x);
    final y3 = p.y * cosX - z2 * sinX;
    final z3 = p.y * sinX + z2 * cosX;

    return Vector3(x2, y3, z3);
  }

  @override
  bool shouldRepaint(GeoPointsPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.points != points;
  }
}
