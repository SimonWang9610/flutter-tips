import 'package:flutter/material.dart';
import 'package:flutter_tips/gallery/grid_gallery.dart';

class GridGalleryExample extends StatefulWidget {
  const GridGalleryExample({Key? key}) : super(key: key);

  @override
  State<GridGalleryExample> createState() => _GridGalleryExampleState();
}

class _GridGalleryExampleState extends State<GridGalleryExample> {
  final List<Widget> galleries = List.generate(
    4,
    (index) => GestureDetector(
      child: Text('$index'),
      onTap: () {
        print('tap: $index');
      },
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
          child: GridGallery(galleries: galleries),
        ),
      ),
    );
  }
}
