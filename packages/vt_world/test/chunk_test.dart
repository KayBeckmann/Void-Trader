import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('ChunkCoord', () {
    test('gleiche Koordinaten sind gleich und hashen gleich', () {
      expect(const ChunkCoord(2, -3), equals(const ChunkCoord(2, -3)));
      expect(
        const ChunkCoord(2, -3).hashCode,
        equals(const ChunkCoord(2, -3).hashCode),
      );
    });

    test('unterschiedliche Koordinaten sind ungleich', () {
      expect(const ChunkCoord(2, -3), isNot(equals(const ChunkCoord(3, -3))));
    });
  });

  group('Chunk', () {
    test('layerAt wirft für nicht vorhandene Ebene', () {
      final chunk = Chunk(const ChunkCoord(0, 0), {});
      expect(() => chunk.layerAt(ZLevel.surface), throwsArgumentError);
    });

    test('ChunkLayer erlaubt Lesen/Schreiben einzelner Tiles', () {
      final tiles = List.generate(
        Chunk.size,
        (_) => List.generate(Chunk.size, (_) => const Tile(TileType.grass)),
      );
      final layer = ChunkLayer(ZLevel.surface, tiles);
      expect(layer.tileAt(5, 7).type, TileType.grass);

      layer.setTile(5, 7, const Tile(TileType.water));
      expect(layer.tileAt(5, 7).type, TileType.water);
    });
  });
}
