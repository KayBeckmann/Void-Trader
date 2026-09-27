import 'package:test/test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('World.stepForestGrowth (Roadmap: Wald regeneriert/breitet sich aus)', () {
    /// Legt ein 5×5-Feld reiner Wiese um (originX, originY) an, mit genau
    /// einem Wald-Tile am linken Rand als Wachstumsquelle — kontrolliert
    /// statt auf natürlicher Generierung zu basieren, damit die Tests nicht
    /// von Seed-Zufall abhängen.
    World worldWithGrassPatchAndForestSource(int originX, int originY) {
      final world = World(1);
      for (var dy = -2; dy <= 2; dy++) {
        for (var dx = -2; dx <= 2; dx++) {
          world.setTileAt(originX + dx, originY + dy, ZLevel.surface, const Tile(TileType.grass));
        }
      }
      world.setTileAt(
        originX - 3,
        originY,
        ZLevel.surface,
        const Tile(TileType.forest),
      );
      return world;
    }

    test('Wiese neben Wald wird über genug Ticks zu Wald (Regeneration/Ausbreitung)', () {
      final world = worldWithGrassPatchAndForestSource(50, 50);
      // (47,50) ist die Wald-Quelle, (48,50) ihr einziger direkter
      // Wiesen-Nachbar — genau dieses Tile sollte irgendwann wachsen.

      var grewAtLeastOnce = false;
      for (var tick = 0; tick < 500; tick++) {
        world.stepForestGrowth(originX: 45, originY: 45, width: 11, height: 11, tick: tick);
        if (world.tileAt(48, 50, ZLevel.surface).type == TileType.forest) {
          grewAtLeastOnce = true;
          break;
        }
      }

      expect(
        grewAtLeastOnce,
        isTrue,
        reason: 'Wiese direkt neben einer Wald-Quelle sollte irgendwann nachwachsen',
      );
    });

    test('isolierte Wiese ohne Wald-Nachbarn wächst nie zu Wald, egal wie viele Ticks', () {
      final world = World(1);
      for (var dy = -2; dy <= 2; dy++) {
        for (var dx = -2; dx <= 2; dx++) {
          world.setTileAt(100 + dx, 100 + dy, ZLevel.surface, const Tile(TileType.grass));
        }
      }
      // Umgebung bewusst Stein statt Wald, damit kein Nachbar-Wald existiert.
      for (var dy = -3; dy <= 3; dy++) {
        world.setTileAt(97, 100 + dy, ZLevel.surface, const Tile(TileType.stone));
        world.setTileAt(103, 100 + dy, ZLevel.surface, const Tile(TileType.stone));
      }

      for (var tick = 0; tick < 500; tick++) {
        world.stepForestGrowth(originX: 95, originY: 95, width: 11, height: 11, tick: tick);
      }

      for (var dy = -2; dy <= 2; dy++) {
        for (var dx = -2; dx <= 2; dx++) {
          expect(
            world.tileAt(100 + dx, 100 + dy, ZLevel.surface).type,
            TileType.grass,
            reason: 'Tile (${100 + dx},${100 + dy}) hatte keinen Wald-Nachbarn',
          );
        }
      }
    });

    test('Wiese unter einem Gebäude wächst nie zu Wald', () {
      final world = worldWithGrassPatchAndForestSource(200, 200);
      world.placeBuildingAt(199, 200, ZLevel.surface, BuildingType.storage);

      for (var tick = 0; tick < 500; tick++) {
        world.stepForestGrowth(originX: 195, originY: 195, width: 11, height: 11, tick: tick);
      }

      expect(world.tileAt(199, 200, ZLevel.surface).type, TileType.grass);
    });

    test('Wiese in der sicheren Startzone wächst nie zu Wald (Basis bleibt frei)', () {
      final world = World(1);
      // (0,0) liegt in der sicheren Startzone (Radius 4) und ist per
      // Generierung ohnehin Wiese; direkt daneben ein Wald-Tile als Quelle.
      world.setTileAt(1, 0, ZLevel.surface, const Tile(TileType.forest));

      for (var tick = 0; tick < 500; tick++) {
        world.stepForestGrowth(originX: -5, originY: -5, width: 11, height: 11, tick: tick);
      }

      expect(world.tileAt(0, 0, ZLevel.surface).type, TileType.grass);
    });

    test('ist deterministisch: gleicher Seed + gleiche Tick-Folge -> gleiches Ergebnis', () {
      final worldA = worldWithGrassPatchAndForestSource(300, 300);
      final worldB = worldWithGrassPatchAndForestSource(300, 300);

      for (var tick = 0; tick < 200; tick++) {
        worldA.stepForestGrowth(originX: 295, originY: 295, width: 11, height: 11, tick: tick);
        worldB.stepForestGrowth(originX: 295, originY: 295, width: 11, height: 11, tick: tick);
      }

      for (var dy = -2; dy <= 2; dy++) {
        for (var dx = -2; dx <= 2; dx++) {
          expect(
            worldA.tileAt(300 + dx, 300 + dy, ZLevel.surface),
            worldB.tileAt(300 + dx, 300 + dy, ZLevel.surface),
          );
        }
      }
    });
  });
}
