import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tips/planet/helper.dart';
import 'package:flutter_tips/sphere/models.dart';
import 'package:flutter_tips/sphere/painters.dart';

class SphereRotationExamplePage extends StatefulWidget {
  const SphereRotationExamplePage({super.key});

  @override
  State<SphereRotationExamplePage> createState() =>
      _SphereRotationExamplePageState();
}

class _SphereRotationExamplePageState extends State<SphereRotationExamplePage>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  ui.Image? _texture;
  ui.FragmentProgram? _frag;

  final ValueNotifier<Rotation> _rotation = ValueNotifier(const Rotation());

  double _radius = 300;

  @override
  void initState() {
    super.initState();
    _loadImage('assets/earth-day.jpg');
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotation.dispose();
    super.dispose();
  }

  void _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(Uint8List.view(data.buffer));
    final frame = await codec.getNextFrame();

    _texture = frame.image;

    _frag = await ui.FragmentProgram.fromAsset('shaders/sphere_rotation.frag');

    setState(() {});
  }

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
        (e) => SpherePoint(e, _radius),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    if (_frag == null || _texture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final child = ListenableBuilder(
      listenable: Listenable.merge([_controller, _rotation]),
      builder: (context, child) {
        // final r = _controller.value * 2 * pi;
        // print('r: $r');
        // final rotation = Rotation(
        //   x: r,
        //   y: r,
        // );

        final children = <Widget>[];

        for (var i = 0; i < points.length; i++) {
          final point = points[i];

          final m = point.rotate(_rotation.value);

          // children.add(Transform(
          //   transform: m,
          //   child: Text(
          //     names[i],
          //     style: const TextStyle(
          //       color: Colors.red,
          //       fontSize: 12,
          //     ),
          //   ),
          // ));

          final offset = point.rotateOffset(_rotation.value);

          children.add(
            Positioned(
              left: offset.dx,
              top: offset.dy,
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
          size: Size.square(_radius * 2),
          painter: SphereRotationPainter(
            _frag!.fragmentShader(),
            texture: _texture!,
            scale: 1.0,
            rotation: _rotation.value,
          ),
          child: SizedBox.square(
            dimension: _radius * 2,
            child: Transform(
              transform: _rotation.value.transform,
              child: Stack(
                // alignment: Alignment.center,
                children: children,
              ),
            ),
          ),
        );
      },
    );

    return Scaffold(
      body: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              child: child,
            ),
          ),
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
          )
        ],
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final delta = details.delta;
    final dx = -delta.dy / _radius * pi + _rotation.value.x;
    final dy = delta.dx / _radius * pi + _rotation.value.y;

    // final dz = delta.distance / _radius * pi + _rotation.value.z;

    _rotation.value = _rotation.value.copyWith(
      x: dx,
      y: dy,
      // z: dz,
    );
  }
}
