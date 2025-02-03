import 'dart:ui';

Future<FragmentProgram> loadShader(String path) async {
  final shader = await FragmentProgram.fromAsset(path);
  return shader;
}
