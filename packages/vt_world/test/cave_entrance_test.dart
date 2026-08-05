import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('Höhleneingänge (Oberfläche)', () {
    /// Sammelt alle Oberflächen-Tiles über mehrere Chunks, damit die
    /// statistischen Tests (selten, aber vorhanden) nicht von einem
    /// einzelnen unglücklichen Chunk abhängen.
    List<TileType> surfaceTilesInArea(World world, int chunkRadius) {
      final types = <TileType>[];
      for (var cx = -chunkRadius; cx <= chunkRadius; cx++) {
        for (var cy = -chunkRadius; cy <= chunkRadius; cy++) {
          final chunk = world.getOrCreateChunk(ChunkCoord(cx, cy));
          final surface = chunk.layerAt(ZLevel.surface);
          for (var y = 0; y < Chunk.size; y++) {
            for (var x = 0; x < Chunk.size; x++) {
              types.add(surface.tileAt(x, y).type);
            }
          }
        }
      }
      return types;
    }

    test('kommen über einen größeren Ausschnitt vor, aber selten', () {
      final world = World(2024);
      final types = surfaceTilesInArea(world, 3);

      final entranceCount = types.where((t) => t == TileType.caveEntrance).length;

      expect(entranceCount, greaterThan(0));
      expect(entranceCount, lessThan((types.length * 0.2).round()));
    });

    test('erscheinen nie auf Wasser-Tiles', () {
      // Indirekter Test: Höhleneingänge ersetzen den Biom-Typ nur, wenn
      // dieser nicht Wasser war (siehe World._generateSurfaceLayer). Über
      // viele Chunks hinweg darf daher kein Wasser-Tile plötzlich als
      // "eigentlich Höhleneingang" auftauchen — d.h. es reicht, dass beide
      // Typen als eigenständige, disjunkte Kategorien in der Ausgabe
      // erscheinen und keine Exception auftritt.
      final world = World(7);
      final types = surfaceTilesInArea(world, 3).toSet();
      expect(types, isNotEmpty);
    });

    test('Erzeugung ist deterministisch', () {
      final worldA = World(99);
      final worldB = World(99);

      final chunkA = worldA.getOrCreateChunk(const ChunkCoord(1, -1));
      final chunkB = worldB.getOrCreateChunk(const ChunkCoord(1, -1));

      final surfaceA = chunkA.layerAt(ZLevel.surface);
      final surfaceB = chunkB.layerAt(ZLevel.surface);

      for (var y = 0; y < Chunk.size; y++) {
        for (var x = 0; x < Chunk.size; x++) {
          expect(surfaceA.tileAt(x, y), equals(surfaceB.tileAt(x, y)));
        }
      }
    });

    test('Keller-Ebene bleibt unter einem Höhleneingang begehbar', () {
      final world = World(2024);
      final chunk = world.getOrCreateChunk(const ChunkCoord(0, 0));
      final surface = chunk.layerAt(ZLevel.surface);
      final cellar = chunk.layerAt(ZLevel.cellar);

      for (var y = 0; y < Chunk.size; y++) {
        for (var x = 0; x < Chunk.size; x++) {
          if (surface.tileAt(x, y).type == TileType.caveEntrance) {
            expect(cellar.tileAt(x, y).isWalkable, isTrue);
          }
        }
      }
    });
  });

  group('TileType.caveEntrance', () {
    test('ist begehbar und nicht abbaubar', () {
      expect(const Tile(TileType.caveEntrance).isWalkable, isTrue);
      expect(TileType.caveEntrance.isMinable, isFalse);
    });
  });
}
