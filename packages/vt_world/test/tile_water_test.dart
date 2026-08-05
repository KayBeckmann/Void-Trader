import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('Tile.waterLevel', () {
    test('default ist 0', () {
      expect(const Tile(TileType.grass).waterLevel, 0);
    });

    test('wirft bei negativem Wasserstand', () {
      expect(
        () => Tile(TileType.grass, waterLevel: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('wirft, wenn ein solides Tile Wasser tragen soll', () {
      expect(
        () => Tile(TileType.stone, waterLevel: 1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Tile(TileType.rockWall, waterLevel: 0.5),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Tile(TileType.ore, waterLevel: 0.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith ändert waterLevel unabhängig vom Typ', () {
      const tile = Tile(TileType.path, waterLevel: 0.2);
      final updated = tile.copyWith(waterLevel: 0.8);
      expect(updated.type, TileType.path);
      expect(updated.waterLevel, 0.8);
    });

    test('Gleichheit berücksichtigt sowohl Typ als auch Wasserstand', () {
      expect(
        const Tile(TileType.grass, waterLevel: 0.5),
        equals(const Tile(TileType.grass, waterLevel: 0.5)),
      );
      expect(
        const Tile(TileType.grass, waterLevel: 0.5),
        isNot(equals(const Tile(TileType.grass, waterLevel: 0.6))),
      );
    });
  });

  group('World.peekTileAt', () {
    test('liefert null für nicht geladene Chunks, ohne zu generieren', () {
      final world = World(1);
      expect(world.peekTileAt(1000, 1000, ZLevel.surface), isNull);
      expect(world.loadedChunkCount, 0);
    });

    test('liefert das Tile, sobald der Chunk geladen wurde', () {
      final world = World(1);
      world.getOrCreateChunk(const ChunkCoord(0, 0));
      expect(world.peekTileAt(5, 5, ZLevel.surface), isNotNull);
    });
  });

  group('Wasser-Biom startet mit vollem Wasserstand', () {
    test('generierte Wasser-Tiles haben waterLevel 1', () {
      final world = World(456);
      var foundWater = false;
      for (var cx = -2; cx <= 2 && !foundWater; cx++) {
        for (var cy = -2; cy <= 2 && !foundWater; cy++) {
          final chunk = world.getOrCreateChunk(ChunkCoord(cx, cy));
          final surface = chunk.layerAt(ZLevel.surface);
          for (var y = 0; y < Chunk.size; y++) {
            for (var x = 0; x < Chunk.size; x++) {
              final tile = surface.tileAt(x, y);
              if (tile.type == TileType.water) {
                expect(tile.waterLevel, 1.0);
                foundWater = true;
                break;
              }
            }
          }
        }
      }
      expect(foundWater, isTrue, reason: 'Über mehrere Chunks sollte mindestens ein See auftauchen');
    });
  });
}
