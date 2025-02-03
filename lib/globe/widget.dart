import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'models.dart';
import 'painters.dart';

final locations = [
  Geolocation(
    name: "London",
    latitude: 51.5072,
    longitude: -0.1276,
  ),
  Geolocation(
    name: "New York",
    latitude: 40.7128,
    longitude: -74.0060,
  ),
  Geolocation(
    name: "Tokyo",
    latitude: 35.6895,
    longitude: 139.6917,
  ),
  Geolocation(
    name: "Toronto",
    latitude: 43.6532,
    longitude: -79.3832,
  ),
  // north pole
  Geolocation(
    name: "North Pole",
    latitude: 90,
    longitude: 0,
  ),
  // south pole
  Geolocation(
    name: "South Pole",
    latitude: -90,
    longitude: 0,
  ),
  // equator
  Geolocation(
    name: "Equator",
    latitude: 0,
    longitude: 0,
  ),
];

class ShaderGlobePage extends StatefulWidget {
  final TextureShader textureShader;
  const ShaderGlobePage({
    super.key,
    required this.textureShader,
  });

  @override
  State<ShaderGlobePage> createState() => _ShaderGlobePageState();
}

class _ShaderGlobePageState extends State<ShaderGlobePage>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );

  @override
  void initState() {
    super.initState();
    _load();

    _controller.addListener(() {
      _rotation.value = _rotation.value.copyWith(y: _controller.value * 2 * pi);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ui.FragmentShader? _shader;
  ui.Image? _texture;

  final _rotation = ValueNotifier(const Rotation());

  void _load() async {
    await widget.textureShader.load();

    _texture = widget.textureShader.texture;
    _shader = widget.textureShader.shader;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null || _texture == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final size = Size.square(400);

    final texture = ValueListenableBuilder(
      valueListenable: _rotation,
      builder: (_, rotation, __) {
        return CustomPaint(
          size: size,
          // painter: SphereGridPainter(
          //   rotation: rotation,
          //   latitudeGap: 30,
          //   longitudeGap: 30,
          // ),
          painter: SphereImageTexturePainter(
            _shader!,
            rotation: rotation,
            texture: _texture!,
          ),
          // foregroundPainter: GeolocationPainter(
          //   locations,
          //   rotation: rotation,
          // ),
        );
      },
    );

    final points = locations
        .map(
          (e) => SpherePoint(
            location: e,
            rotation: _rotation,
            size: size,
          ),
        )
        .toList();

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                texture,
                ...points,
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _rotation.value = const Rotation();
                  },
                  child: const Text("Reset"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.isAnimating) {
                      _controller.stop();
                    } else {
                      _controller.repeat();
                    }
                  },
                  child: const Text("animate"),
                ),
                ElevatedButton(
                  onPressed: () {
                    focusIndex(0);
                  },
                  child: const Text("Focus London"),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isDragging = false;
  Offset? _lastPosition;

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _lastPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _lastPosition == null) return;

    final delta = details.localPosition - _lastPosition!;

    final rotation = _rotation.value;

    final y = rotation.y + delta.dx * 0.01;
    final x = (rotation.x + delta.dy * 0.01).clamp(-pi / 2, pi / 2);

    _rotation.value = rotation.copyWith(y: y, x: x);

    _lastPosition = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _lastPosition = null;
  }

  void focusIndex(int index) {
    // focus the selected location in the original equator position
    final location = locations[index];

    final rotation = Rotation(
      x: -location.latitude * pi / 180,
      y: -location.longitude * pi / 180,
    );
  }
}

class SpherePoint extends StatelessWidget {
  final Geolocation location;
  final ValueNotifier<Rotation> rotation;
  final Size size;
  const SpherePoint({
    super.key,
    required this.location,
    required this.rotation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: rotation,
      builder: (_, rotation, __) {
        return CustomPaint(
          size: size,
          painter: SingleGeolocationPainter(
            location,
            rotation: rotation,
          ),
        );
        // final center = size.center(Offset.zero);
        // final pos = location.toCartesianPoint(size.shortestSide / 2);
        // final transformed =
        //     Geolocation.rotate(pos, rotation + const Rotation(x: pi / 2));

        // final x = center.dx + transformed.x;
        // final y = center.dy + transformed.y;

        // // project

        // return Positioned(
        //   left: x,
        //   top: y,
        //   child: GestureDetector(
        //     onTap: () {
        //       showAboutDialog(context: context, applicationName: location.name);
        //     },
        //     child: Row(
        //       mainAxisSize: MainAxisSize.min,
        //       children: [
        //         Text(
        //           location.name ?? "",
        //           style: const TextStyle(
        //             color: Colors.red,
        //             fontSize: 12,
        //           ),
        //         ),
        //         const SizedBox(width: 4),
        //         Container(
        //           width: 10,
        //           height: 10,
        //           decoration: BoxDecoration(
        //             color: transformed.z < 0 ? Colors.green : Colors.grey,
        //             shape: BoxShape.circle,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // );
      },
    );
  }
}
