import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('World Determinismus', () {
    test('gleicher Seed + gleiche Chunk-Koordinate erzeugt gleiche Tiles', () {
      final worldA = World(42);
      final worldB = World(42);

      final chunkA = worldA.getOrCreateChunk(const ChunkCoord(3, -1));
      final chunkB = worldB.getOrCreateChunk(const ChunkCoord(3, -1));

      for (final z in ZLevel.all) {
        final layerA = chunkA.layerAt(z);
        final layerB = chunkB.layerAt(z);
        for (var y = 0; y < Chunk.size; y++) {
          for (var x = 0; x < Chunk.size; x++) {
            expect(
              layerA.tileAt(x, y),
              equals(layerB.tileAt(x, y)),
              reason: 'Tile ($x,$y,$z) sollte bei gleichem Seed identisch sein',
            );
          }
        }
      }
    });

    test('unterschiedlicher Seed erzeugt (meist) unterschiedliche Tiles', () {
      final worldA = World(1);
      final worldB = World(2);

      final chunkA = worldA.getOrCreateChunk(const ChunkCoord(0, 0));
      final chunkB = worldB.getOrCreateChunk(const ChunkCoord(0, 0));

      final layerA = chunkA.layerAt(ZLevel.surface);
      final layerB = chunkB.layerAt(ZLevel.surface);

      var differences = 0;
      for (var y = 0; y < Chunk.size; y++) {
        for (var x = 0; x < Chunk.size; x++) {
          if (layerA.tileAt(x, y) != layerB.tileAt(x, y)) differences++;
        }
      }
      expect(differences, greaterThan(0));
    });

    test('getOrCreateChunk liefert denselben Chunk bei wiederholtem Aufruf', () {
      final world = World(7);
      final first = world.getOrCreateChunk(const ChunkCoord(0, 0));
      final second = world.getOrCreateChunk(const ChunkCoord(0, 0));
      expect(identical(first, second), isTrue);
      expect(world.loadedChunkCount, 1);
    });

    test('peekChunk gibt null zurück solange nichts generiert wurde', () {
      final world = World(7);
      expect(world.peekChunk(const ChunkCoord(5, 5)), isNull);
      world.getOrCreateChunk(const ChunkCoord(5, 5));
      expect(world.peekChunk(const ChunkCoord(5, 5)), isNotNull);
    });
  });

  group('World Welt-Koordinaten', () {
    test('chunkCoordForWorldTile rundet auch für negative Koordinaten ab', () {
      expect(
        World.chunkCoordForWorldTile(0, 0),
        equals(const ChunkCoord(0, 0)),
      );
      expect(
        World.chunkCoordForWorldTile(31, 31),
        equals(const ChunkCoord(0, 0)),
      );
      expect(
        World.chunkCoordForWorldTile(32, 0),
        equals(const ChunkCoord(1, 0)),
      );
      expect(
        World.chunkCoordForWorldTile(-1, -1),
        equals(const ChunkCoord(-1, -1)),
      );
      expect(
        World.chunkCoordForWorldTile(-32, 0),
        equals(const ChunkCoord(-1, 0)),
      );
      expect(
        World.chunkCoordForWorldTile(-33, 0),
        equals(const ChunkCoord(-2, 0)),
      );
    });

    test('tileAt/setTileAt arbeiten über Chunk-Grenzen hinweg konsistent', () {
      final world = World(99);
      world.setTileAt(-1, -1, ZLevel.surface, const Tile(TileType.path));
      expect(world.tileAt(-1, -1, ZLevel.surface).type, TileType.path);

      // Nachbar-Tile im selben Chunk bleibt unberührt.
      expect(world.tileAt(-2, -1, ZLevel.surface).type, isNot(TileType.path));
    });

    test('Oberfläche besteht nur aus gültigen Biom-Tiles, Berge aus Stein', () {
      final world = World(123);
      final chunk = world.getOrCreateChunk(const ChunkCoord(0, 0));

      final surface = chunk.layerAt(ZLevel.surface);
      const validSurfaceTypes = {
        TileType.grass,
        TileType.dirt,
        TileType.forest,
        TileType.stone,
        TileType.water,
      };
      for (var y = 0; y < Chunk.size; y++) {
        for (var x = 0; x < Chunk.size; x++) {
          expect(validSurfaceTypes, contains(surface.tileAt(x, y).type));
        }
      }

      final mountains = chunk.layerAt(ZLevel.mountains);
      for (var y = 0; y < Chunk.size; y++) {
        for (var x = 0; x < Chunk.size; x++) {
          expect(mountains.tileAt(x, y).type, TileType.stone);
        }
      }
    });

    test('Oberflächengenerierung nutzt Höhen-/Feuchtigkeits-/Temperatur-Noise (Biom-Vielfalt)', () {
      // Über einen größeren Ausschnitt sollten mehrere Biom-Typen auftauchen,
      // nicht nur ein einzelner Standardwert — sonst würde Noise nichts tun.
      final world = World(456);
      final types = <TileType>{};
      for (var cx = -2; cx <= 2; cx++) {
        for (var cy = -2; cy <= 2; cy++) {
          final chunk = world.getOrCreateChunk(ChunkCoord(cx, cy));
          final surface = chunk.layerAt(ZLevel.surface);
          for (var y = 0; y < Chunk.size; y++) {
            for (var x = 0; x < Chunk.size; x++) {
              types.add(surface.tileAt(x, y).type);
            }
          }
        }
      }
      expect(types.length, greaterThan(1));
    });
  });
}
