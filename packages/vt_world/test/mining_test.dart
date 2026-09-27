import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('TileMining', () {
    test('Stein, Felswand, Erz und Wald sind abbaubar', () {
      expect(TileType.stone.isMinable, isTrue);
      expect(TileType.rockWall.isMinable, isTrue);
      expect(TileType.ore.isMinable, isTrue);
      // Wald abbaubar seit Kays Feedback 2026-09-27 ("Holz/Wald sollte man
      // auch abbauen können") — anders als Fels/Erz blockiert Wald die
      // Bewegung nicht (siehe TileMovement.blocksMovement), ist aber
      // trotzdem eine eigenständige Ressourcenquelle mit Ertrag Holz.
      expect(TileType.forest.isMinable, isTrue);
    });

    test('Gras, Erde, Wasser etc. sind nicht abbaubar', () {
      for (final type in [
        TileType.grass,
        TileType.dirt,
        TileType.water,
        TileType.farmland,
        TileType.path,
        TileType.empty,
        TileType.caveEntrance,
      ]) {
        expect(type.isMinable, isFalse, reason: '$type sollte nicht abbaubar sein');
      }
    });

    test('minedResult liefert path, außer bei Wald (liefert gerodete Wiese)', () {
      expect(TileType.stone.minedResult, TileType.path);
      expect(TileType.rockWall.minedResult, TileType.path);
      expect(TileType.ore.minedResult, TileType.path);
      expect(TileType.forest.minedResult, TileType.grass);
    });

    test('minedResult wirft für nicht abbaubare Tiles', () {
      expect(() => TileType.grass.minedResult, throwsA(isA<AssertionError>()));
    });
  });

  group('World.mineTileAt', () {
    test('baut ein abbaubares Tile ab und liefert den Ursprungstyp', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.mountains, const Tile(TileType.stone));

      final mined = world.mineTileAt(0, 0, ZLevel.mountains);

      expect(mined, TileType.stone);
      expect(world.tileAt(0, 0, ZLevel.mountains).type, TileType.path);
    });

    test('liefert null für nicht abbaubare Tiles und ändert nichts', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.grass));

      final mined = world.mineTileAt(0, 0, ZLevel.surface);

      expect(mined, isNull);
      expect(world.tileAt(0, 0, ZLevel.surface).type, TileType.grass);
    });

    test('erneutes Abbauen derselben Stelle schlägt fehl (schon path)', () {
      final world = World(1);
      world.setTileAt(5, 5, ZLevel.caves, const Tile(TileType.rockWall));

      expect(world.mineTileAt(5, 5, ZLevel.caves), TileType.rockWall);
      expect(world.mineTileAt(5, 5, ZLevel.caves), isNull);
    });
  });
}
