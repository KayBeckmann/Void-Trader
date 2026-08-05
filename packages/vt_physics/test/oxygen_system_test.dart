import 'package:test/test.dart';
import 'package:vt_physics/vt_physics.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('OxygenSystem.regionStateAt', () {
    test('Oberflächen-Ebene ist immer openSurface, unabhängig vom Tile', () {
      final world = World(1);
      final system = OxygenSystem(world);
      expect(
        system.regionStateAt(0, 0, ZLevel.surface),
        OxygenRegionState.openSurface,
      );
    });

    test('Start-Tile solide oder nicht geladen -> sealed', () {
      final world = World(1);
      final system = OxygenSystem(world);

      world.setTileAt(0, 0, ZLevel.caves, const Tile(TileType.rockWall));
      expect(system.regionStateAt(0, 0, ZLevel.caves), OxygenRegionState.sealed);

      expect(
        system.regionStateAt(1000, 1000, ZLevel.caves),
        OxygenRegionState.sealed,
      );
    });

    test('vollständig von Fels umschlossene Kammer ist sealed', () {
      final world = World(1);
      const z = ZLevel.caves;

      for (var x = 4; x <= 6; x++) {
        for (var y = 4; y <= 6; y++) {
          world.setTileAt(x, y, z, const Tile(TileType.rockWall));
        }
      }
      world.setTileAt(5, 5, z, const Tile(TileType.path));

      final result = OxygenSystem(world).regionStateAt(5, 5, z);
      expect(result, OxygenRegionState.sealed);
    });

    test('ein Gang bis zum Rand eines geladenen Chunks gilt als open', () {
      final world = World(1);
      const z = ZLevel.caves;

      // 1 Tile breiter Gang von (5,5) bis (31,5), links und in der Wand
      // ringsum abgeriegelt — reicht bis zum Rand von Chunk (0,0). Chunk
      // (1,0) ist nicht geladen, die Suche muss dort mit "open" abbrechen.
      world.setTileAt(4, 5, z, const Tile(TileType.rockWall));
      for (var x = 5; x <= 31; x++) {
        world.setTileAt(x, 5, z, const Tile(TileType.path));
        world.setTileAt(x, 4, z, const Tile(TileType.rockWall));
        world.setTileAt(x, 6, z, const Tile(TileType.rockWall));
      }

      final result = OxygenSystem(world).regionStateAt(5, 5, z, maxTiles: 400);
      expect(result, OxygenRegionState.open);
    });

    test('großer offener Bereich gilt bei kleinem Budget als open (Budget erschöpft)', () {
      final world = World(1);
      const z = ZLevel.caves;

      for (var x = 0; x < 15; x++) {
        for (var y = 0; y < 15; y++) {
          world.setTileAt(x, y, z, const Tile(TileType.path));
        }
      }

      final result = OxygenSystem(world).regionStateAt(7, 7, z, maxTiles: 5);
      expect(result, OxygenRegionState.open);
    });

    test('generiert keine neuen Chunks während der Suche', () {
      final world = World(1);
      const z = ZLevel.caves;
      world.setTileAt(5, 5, z, const Tile(TileType.path));

      final before = world.loadedChunkCount;
      OxygenSystem(world).regionStateAt(5, 5, z);
      expect(world.loadedChunkCount, before);
    });

    test('ist deterministisch (wiederholter Aufruf liefert dasselbe Ergebnis)', () {
      final world = World(1);
      const z = ZLevel.caves;
      for (var x = 4; x <= 6; x++) {
        for (var y = 4; y <= 6; y++) {
          world.setTileAt(x, y, z, const Tile(TileType.rockWall));
        }
      }
      world.setTileAt(5, 5, z, const Tile(TileType.path));

      final system = OxygenSystem(world);
      final first = system.regionStateAt(5, 5, z);
      final second = system.regionStateAt(5, 5, z);
      expect(first, second);
    });
  });
}
