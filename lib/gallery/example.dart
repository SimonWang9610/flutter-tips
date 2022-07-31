import 'package:flutter/material.dart';
import 'package:flutter_tips/gallery/grid_gallery.dart';

final List<IconData> icons = [
  Icons.abc,
  Icons.back_hand,
  Icons.cabin,
  Icons.dangerous,
  Icons.earbuds,
  Icons.face,
  Icons.gamepad,
  Icons.h_plus_mobiledata,
  Icons.image,
];

class GridGalleryExample extends StatefulWidget {
  const GridGalleryExample({Key? key}) : super(key: key);

  @override
  State<GridGalleryExample> createState() => _GridGalleryExampleState();
}

class _GridGalleryExampleState extends State<GridGalleryExample> {
  final List<Widget> galleries = List.generate(
    4,
    (index) => IconButton(
      onPressed: () {},
      icon: Icon(icons[index]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grid Gallery Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all()),
            child: GridGallery(galleries: galleries),
          ),
        ),
      ),
    );
  }
}
