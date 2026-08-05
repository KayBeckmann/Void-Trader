import 'package:test/test.dart';
import 'package:vt_physics/vt_physics.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('WorldFluidBridge', () {
    test('buildGrid generiert keine neuen Chunks (bleibt budgetiert)', () {
      final world = World(1);
      final bridge = WorldFluidBridge(world, ZLevel.surface);

      bridge.buildGrid(originX: -10, originY: -10, width: 20, height: 20);

      expect(world.loadedChunkCount, 0);
    });

    test('nicht geladene Bereiche werden als solide/trocken behandelt', () {
      final world = World(1);
      final bridge = WorldFluidBridge(world, ZLevel.surface);

      final grid = bridge.buildGrid(originX: 100, originY: 100, width: 4, height: 4);

      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          expect(grid.cellAt(x, y).solid, isTrue);
          expect(grid.cellAt(x, y).waterLevel, 0);
        }
      }
    });

    test('Wasser aus einem See fließt durch ein abgebautes Tile in eine Höhle', () {
      final world = World(1);
      const z = ZLevel.surface;

      // Handgebaute Szene: See | offenes Tile | Fels — See soll ins offene
      // Tile fließen, aber nicht durch den Fels dahinter.
      world.setTileAt(0, 0, z, const Tile(TileType.water, waterLevel: 1.0));
      world.setTileAt(1, 0, z, const Tile(TileType.path));
      world.setTileAt(2, 0, z, const Tile(TileType.rockWall));

      final bridge = WorldFluidBridge(world, z);
      for (var i = 0; i < 10; i++) {
        bridge.step(originX: 0, originY: 0, width: 3, height: 1);
      }

      expect(world.tileAt(1, 0, z).waterLevel, greaterThan(0));
      expect(world.tileAt(2, 0, z).waterLevel, 0);
      expect(world.tileAt(2, 0, z).isSolid, isTrue);
    });

    test('applyGrid überspringt solide Tiles und nicht geladene Bereiche', () {
      final world = World(1);
      const z = ZLevel.surface;
      world.setTileAt(0, 0, z, const Tile(TileType.rockWall));

      final bridge = WorldFluidBridge(world, z);
      final grid = bridge.buildGrid(originX: 0, originY: 0, width: 1, height: 1);
      grid.cellAt(0, 0); // solid, unverändert

      // Sollte nicht werfen, obwohl das Tile solide ist.
      bridge.applyGrid(grid, originX: 0, originY: 0);
      expect(world.tileAt(0, 0, z).type, TileType.rockWall);
      expect(world.tileAt(0, 0, z).waterLevel, 0);
    });

    test('step() ist über mehrere Aufrufe hinweg deterministisch', () {
      final worldA = World(7);
      final worldB = World(7);
      worldA.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.water, waterLevel: 1.0));
      worldB.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.water, waterLevel: 1.0));

      final bridgeA = WorldFluidBridge(worldA, ZLevel.surface);
      final bridgeB = WorldFluidBridge(worldB, ZLevel.surface);

      for (var i = 0; i < 5; i++) {
        bridgeA.step(originX: -2, originY: -2, width: 5, height: 5);
        bridgeB.step(originX: -2, originY: -2, width: 5, height: 5);
      }

      for (var x = -2; x < 3; x++) {
        for (var y = -2; y < 3; y++) {
          expect(
            worldA.tileAt(x, y, ZLevel.surface).waterLevel,
            worldB.tileAt(x, y, ZLevel.surface).waterLevel,
          );
        }
      }
    });
  });
}
