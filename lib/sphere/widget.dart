import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tips/sphere/models.dart';
import 'package:flutter_tips/sphere/painters.dart';

class SphereShaderExamplePage extends StatefulWidget {
  final double radius;
  const SphereShaderExamplePage({
    super.key,
    this.radius = 200,
  });

  @override
  State<SphereShaderExamplePage> createState() =>
      _SphereShaderExamplePageState();
}

class _SphereShaderExamplePageState extends State<SphereShaderExamplePage>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  final _zoom = ValueNotifier(1.0);

  // london, new york, tokyo, toronto

  final names = const ['London', 'New York', 'Tokyo', 'Toronto'];
  final locations = const [
    Coordinates(
      latitude: 51.5072,
      longitude: 0.1276,
    ),
    Coordinates(
      latitude: 40.7128,
      longitude: -74.0060,
    ),
    Coordinates(
      latitude: 35.6895,
      longitude: 139.6917,
    ),
    Coordinates(
      latitude: -43.6532,
      longitude: 79.3832,
    ),
  ];

  late final points = locations
      .map(
        (e) => SpherePoint(e, widget.radius),
      )
      .toList();

  ui.Image? _texture;
  ui.FragmentProgram? _frag;
  ui.ImageShader? _shader;

  void _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(Uint8List.view(data.buffer));
    final frame = await codec.getNextFrame();

    _texture = frame.image;

    _shader = ui.ImageShader(
      _texture!,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
    );

    _frag = await ui.FragmentProgram.fromAsset('shaders/sphere.frag');

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadImage('assets/earth-day.jpg');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frag == null || _shader == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final child = ListenableBuilder(
      listenable: Listenable.merge([_controller, _zoom]),
      builder: (context, child) {
        final rotation = _controller.value * 2 * pi;

        final children = <Widget>[];

        for (int i = 0; i < points.length; i++) {
          children.add(
            Transform(
              transform: points[i].rotate(Rotation(y: rotation)),
              child: Text(
                names[i],
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }

        return CustomPaint(
          size: Size.square(widget.radius * 2),
          painter: SpherePainter(
            _frag!.fragmentShader(),
            texture: _texture!,
            rotation: rotation,
            scale: _zoom.value,
          ),
          child: SizedBox.square(
            dimension: widget.radius * 2,
            child: Stack(
              alignment: Alignment.center,
              children: children,
            ),
          ),
          // painter: SphereRotationPainter(
          //   _frag!.fragmentShader(),
          //   rotation: Rotation(x: rotation),
          //   texture: _texture!,
          // ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sphere Shader Example'),
      ),
      body: Column(
        children: [
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            child: GestureDetector(
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: child,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_controller.isAnimating) {
                _controller.stop();
              } else {
                _controller.repeat();
              }
            },
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Text(_controller.isAnimating ? 'Stop' : 'Start');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _zoom.value = details.scale;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _zoom.value = _zoom.value.clamp(0.5, 2.0);
  }
}
