import 'package:vt_world/vt_world.dart';

void main() {
  final world = World(1337);
  final chunk = world.getOrCreateChunk(const ChunkCoord(0, 0));
  final surface = chunk.layerAt(ZLevel.surface);

  print('Chunk ${chunk.coord}, Tile (0,0): ${surface.tileAt(0, 0)}');
}
