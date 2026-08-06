import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('Höhlen/Minen (caves/deepCaves)', () {
    Map<TileType, int> countTypes(ChunkLayer layer) {
      final counts = <TileType, int>{};
      for (var y = 0; y < Chunk.size; y++) {
        for (var x = 0; x < Chunk.size; x++) {
          final type = layer.tileAt(x, y).type;
          counts[type] = (counts[type] ?? 0) + 1;
        }
      }
      return counts;
    }

    test('bestehen aus einer Mischung aus Fels, ausgehöhlten Gängen und Erz', () {
      final world = World(321);
      final chunk = world.getOrCreateChunk(const ChunkCoord(4, -2));
      final caves = chunk.layerAt(ZLevel.caves);
      final counts = countTypes(caves);

      expect(counts[TileType.rockWall] ?? 0, greaterThan(0));
      expect(counts[TileType.path] ?? 0, greaterThan(0));
      // Erz ist per Threshold selten, muss also nicht in jedem einzelnen
      // Chunk vorkommen — hier reicht der Nachweis, dass alle erzeugten
      // Typen aus der erwarteten Menge stammen.
      for (final type in counts.keys) {
        expect(
          {TileType.rockWall, TileType.path, TileType.ore},
          contains(type),
        );
      }
    });

    test('caves und deepCaves unterscheiden sich (eigenes Muster pro Ebene)', () {
      final world = World(321);
      final chunk = world.getOrCreateChunk(const ChunkCoord(4, -2));
      final caves = chunk.layerAt(ZLevel.caves);
      final deepCaves = chunk.layerAt(ZLevel.deepCaves);

      var differences = 0;
      for (var y = 0; y < Chunk.size; y++) {
        for (var x = 0; x < Chunk.size; x++) {
          if (caves.tileAt(x, y) != deepCaves.tileAt(x, y)) differences++;
        }
      }
      expect(differences, greaterThan(0));
    });

    test('Erz kommt über mehrere Chunks hinweg vor und ist abbaubar', () {
      final world = World(321);
      var oreFound = false;
      for (var cx = -3; cx <= 3 && !oreFound; cx++) {
        for (var cy = -3; cy <= 3 && !oreFound; cy++) {
          final chunk = world.getOrCreateChunk(ChunkCoord(cx, cy));
          final layer = chunk.layerAt(ZLevel.caves);
          for (var y = 0; y < Chunk.size; y++) {
            for (var x = 0; x < Chunk.size; x++) {
              if (layer.tileAt(x, y).type == TileType.ore) {
                oreFound = true;
                break;
              }
            }
          }
        }
      }
      expect(oreFound, isTrue, reason: 'Über mehrere Chunks sollte mindestens eine Erzader auftauchen');
      expect(TileType.ore.isMinable, isTrue);
      expect(TileType.ore.minedResult, TileType.path);
    });

    test('Berge bleiben durchgehend Stein, Keller durchgehend Erde', () {
      final world = World(321);
      final chunk = world.getOrCreateChunk(const ChunkCoord(0, 0));

      final mountains = chunk.layerAt(ZLevel.mountains);
      for (var y = 0; y < Chunk.size; y++) {
        for (var x = 0; x < Chunk.size; x++) {
          expect(mountains.tileAt(x, y).type, TileType.stone);
        }
      }

      final cellar = chunk.layerAt(ZLevel.cellar);
      for (var y = 0; y < Chunk.size; y++) {
        for (var x = 0; x < Chunk.size; x++) {
          expect(cellar.tileAt(x, y).type, TileType.dirt);
        }
      }
    });

    test('Hügel sind begehbar (Roadmap MOV-03), nicht mehr massiver Stein', () {
      final world = World(321);
      final chunk = world.getOrCreateChunk(const ChunkCoord(0, 0));

      final hills = chunk.layerAt(ZLevel.hills);
      for (var y = 0; y < Chunk.size; y++) {
        for (var x = 0; x < Chunk.size; x++) {
          final type = hills.tileAt(x, y).type;
          expect(
            type == TileType.dirt || type == TileType.slope,
            isTrue,
            reason: 'Hügel-Tile ($x,$y) sollte begehbar sein, war $type',
          );
        }
      }
    });
  });

  group('TileType.ore', () {
    test('ist solide und blockiert Bewegung bis zum Abbau', () {
      expect(const Tile(TileType.ore).isSolid, isTrue);
      expect(const Tile(TileType.ore).isWalkable, isFalse);
    });
  });
}
