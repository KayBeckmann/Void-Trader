import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('Sichere Startzone um den Weltursprung', () {
    test('ist unabhängig vom Seed immer begehbare Wiese', () {
      for (final seed in [1, 42, 999, -7]) {
        final world = World(seed);
        for (var x = -4; x <= 4; x++) {
          for (var y = -4; y <= 4; y++) {
            expect(
              world.tileAt(x, y, ZLevel.surface).type,
              TileType.grass,
              reason: 'Seed $seed, Tile ($x,$y) sollte in der Startzone Wiese sein',
            );
          }
        }
      }
    });

    test('erstreckt sich über mehrere Chunks konsistent um (0,0)', () {
      // Radius 4 überschreitet keine Chunk-Grenze (Chunk-Größe 32), sollte
      // also vollständig in Chunk (0,0) liegen — dennoch über die
      // öffentliche world-Koordinaten-API geprüft statt Chunk-intern.
      final world = World(2024);
      expect(world.tileAt(-4, -4, ZLevel.surface).type, TileType.grass);
      expect(world.tileAt(4, 4, ZLevel.surface).type, TileType.grass);
      expect(world.tileAt(0, 0, ZLevel.surface).type, TileType.grass);
    });
  });
}
