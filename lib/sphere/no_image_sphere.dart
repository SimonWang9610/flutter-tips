import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

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

class Globe3DWidget extends StatefulWidget {
  final String mapImagePath;

  final double width;
  final double height;

  const Globe3DWidget({
    Key? key,
    required this.mapImagePath,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  State<Globe3DWidget> createState() => _Globe3DWidgetState();
}

class _Globe3DWidgetState extends State<Globe3DWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  ui.Image? _mapImage;

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
      latitude: 43.65107,
      longitude: -79.347015,
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
    );
    _loadImage();
  }

  Future<void> _loadImage() async {
    // Load image from asset
    final imageProvider = AssetImage(widget.mapImagePath);
    final ImageStream stream = imageProvider.resolve(ImageConfiguration());

    stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _mapImage = info.image;
      });
    }));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _rotationY += details.delta.dx * 0.01;
      _rotationX += details.delta.dy * 0.01;
      _rotationX = _rotationX.clamp(-math.pi / 2, math.pi / 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mapImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: Globe3DPainter(
              points: points,
              mapImage: _mapImage!,
              rotationX: _rotationX,
              rotationY: _rotationY + _controller.value * 2 * math.pi,
            ),
          );
        },
      ),
    );
  }
}

class Globe3DPainter extends CustomPainter {
  final List<GeoPoint> points;
  final ui.Image mapImage;
  final double rotationX;
  final double rotationY;
  static const int latitudeSections = 60;
  static const int longitudeSections = 60;

  Globe3DPainter({
    required this.points,
    required this.mapImage,
    required this.rotationX,
    required this.rotationY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;

    // Draw sphere segments
    _drawTexturedSphere(canvas, center, radius);

    // Draw points
    for (var point in points) {
      final pos = _geoTo3D(point.latitude, point.longitude, radius);
      final transformed = _transform3D(pos, rotationX, rotationY);

      if (transformed.z > 0) {
        final screenPos = Offset(
          center.dx + transformed.x,
          center.dy + transformed.y,
        );

        final perspectiveScale = (transformed.z + radius) / (2 * radius);
        final adjustedRadius = point.radius * perspectiveScale;

        final paint = Paint()
          ..color = point.color.withOpacity(perspectiveScale)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(screenPos, adjustedRadius, paint);
      }
    }
  }

  void _drawTexturedSphere(Canvas canvas, Offset center, double radius) {
    for (int lat = 0; lat < latitudeSections; lat++) {
      for (int lon = 0; lon < longitudeSections; lon++) {
        final phi1 = lat * math.pi / latitudeSections;
        final phi2 = (lat + 1) * math.pi / latitudeSections;
        final theta1 = lon * 2 * math.pi / longitudeSections;
        final theta2 = (lon + 1) * 2 * math.pi / longitudeSections;

        final vertices = [
          _sphericalToCartesian(phi1, theta1, radius),
          _sphericalToCartesian(phi2, theta1, radius),
          _sphericalToCartesian(phi2, theta2, radius),
          _sphericalToCartesian(phi1, theta2, radius),
        ];

        final transformedVertices =
            vertices.map((v) => _transform3D(v, rotationX, rotationY)).toList();

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

          final m = Matrix4.identity()
            ..scale(mapImage.width.toDouble(), mapImage.height.toDouble())
            ..storage[0] = 1 / mapImage.width
            ..storage[5] = 1 / mapImage.height;

          // Create shader from the map image
          paint.shader = ImageShader(
            mapImage,
            TileMode.clamp,
            TileMode.clamp,
            m.storage,
          );

          // Calculate average Z for depth sorting
          final avgZ =
              transformedVertices.map((v) => v.z).reduce((a, b) => a + b) / 4;
          paint.color =
              Colors.white.withOpacity((avgZ + radius) / (2 * radius));

          canvas.drawPath(path, paint);
          canvas.restore();
        }
      }
    }
  }

  Vector3 _sphericalToCartesian(double phi, double theta, double radius) {
    return Vector3(
      radius * math.sin(phi) * math.cos(theta),
      radius * math.cos(phi),
      radius * math.sin(phi) * math.sin(theta),
    );
  }

  Vector3 _geoTo3D(double lat, double lon, double radius) {
    final phi = (90 - lat) * math.pi / 180;
    final theta = (lon + 180) * math.pi / 180;
    return _sphericalToCartesian(phi, theta, radius);
  }

  Vector3 _transform3D(Vector3 point, double rotX, double rotY) {
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final x2 = point.x * cosY - point.z * sinY;
    final z2 = point.x * sinY + point.z * cosY;

    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);
    final y3 = point.y * cosX - z2 * sinX;
    final z3 = point.y * sinX + z2 * cosX;

    return Vector3(x2, y3, z3);
  }

  @override
  bool shouldRepaint(Globe3DPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.points != points ||
        oldDelegate.mapImage != mapImage;
  }
}

class Vector3 {
  final double x;
  final double y;
  final double z;

  Vector3(this.x, this.y, this.z);
}
