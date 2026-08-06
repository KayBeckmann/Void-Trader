import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('World.reachableTilesFrom', () {
    test('findet alle über begehbare Tiles verbundenen Nachbarn', () {
      final world = World(1);
      // 3x3-Feld aus Wiese, umgeben von Wasser — Flood-Fill sollte an der
      // Wassergrenze stoppen.
      for (var x = -2; x <= 2; x++) {
        for (var y = -2; y <= 2; y++) {
          world.setTileAt(x, y, ZLevel.surface, const Tile(TileType.grass));
        }
      }
      for (var x = -3; x <= 3; x++) {
        world.setTileAt(x, -3, ZLevel.surface, const Tile(TileType.water));
        world.setTileAt(x, 3, ZLevel.surface, const Tile(TileType.water));
      }
      for (var y = -3; y <= 3; y++) {
        world.setTileAt(-3, y, ZLevel.surface, const Tile(TileType.water));
        world.setTileAt(3, y, ZLevel.surface, const Tile(TileType.water));
      }

      final reachable = world.reachableTilesFrom(0, 0, ZLevel.surface);

      expect(reachable.length, 25); // 5x5 begehbares Feld
      expect(reachable, contains((x: 2, y: 2)));
      expect(reachable, isNot(contains((x: 3, y: 0))));
    });

    test('bricht bei maxTiles ab, statt unbegrenzt zu wachsen', () {
      final world = World(1);
      final reachable = world.reachableTilesFrom(0, 0, ZLevel.surface, maxTiles: 10);
      expect(reachable.length, lessThanOrEqualTo(10));
    });
  });

  group('validateStartZone', () {
    test('erkennt eine vollständig eingeschlossene Startzone als unfair', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.grass));
      for (final neighbor in [(x: 1, y: 0), (x: -1, y: 0), (x: 0, y: 1), (x: 0, y: -1)]) {
        world.setTileAt(neighbor.x, neighbor.y, ZLevel.surface, const Tile(TileType.water));
      }

      final report = validateStartZone(world, minReachableTiles: 2);

      expect(report.isFair, isFalse);
      expect(report.reachableTileCount, 1);
    });

    test('erkennt fehlende abbaubare Ressourcen trotz großer Fläche als unfair', () {
      final world = World(1);
      for (var x = -10; x <= 10; x++) {
        for (var y = -10; y <= 10; y++) {
          world.setTileAt(x, y, ZLevel.surface, const Tile(TileType.grass));
        }
      }

      final report = validateStartZone(world, minReachableTiles: 10);

      expect(report.hasReachableMinableResource, isFalse);
      expect(report.isFair, isFalse);
    });

    test('echte generierte Welten sind über mehrere Seeds fair', () {
      for (final seed in [1, 42, 999, -7, 100, 12345]) {
        final world = World(seed);
        final report = validateStartZone(world);
        expect(report.isFair, isTrue, reason: 'Seed $seed: $report');
      }
    });
  });

  group('World-Generation Puffer-Ring (Roadmap MOV-04)', () {
    test('feste Erz-/Steinvorkommen knapp außerhalb der Startzone existieren immer', () {
      for (final seed in [1, 42, 999]) {
        final world = World(seed);
        expect(world.tileAt(5, 0, ZLevel.surface).type, TileType.stone);
        expect(world.tileAt(6, 0, ZLevel.surface).type, TileType.stone);
      }
    });

    test('Puffer-Ring enthält kein Wasser/Wald, das die Startzone umschließen könnte', () {
      for (final seed in [1, 42, 999, -7, 100, 12345]) {
        final world = World(seed);
        for (var x = -7; x <= 7; x++) {
          for (var y = -7; y <= 7; y++) {
            final type = world.tileAt(x, y, ZLevel.surface).type;
            expect(
              type == TileType.water || type == TileType.forest,
              isFalse,
              reason: 'Seed $seed, Tile ($x,$y) sollte im Puffer-Ring kein $type sein',
            );
          }
        }
      }
    });
  });
}
