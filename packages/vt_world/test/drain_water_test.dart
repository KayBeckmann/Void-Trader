import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('World.drainWaterAt (Roadmap MVP: "Graben/Pumpe/Abdichten")', () {
    test('ohne amount entfernt sofort das gesamte Wasser (Abdichten)', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.path, waterLevel: 0.6));

      final drained = world.drainWaterAt(0, 0, ZLevel.surface);

      expect(drained, 0.6);
      expect(world.tileAt(0, 0, ZLevel.surface).waterLevel, 0);
    });

    test('mit amount entfernt höchstens den angegebenen Betrag (Pumpe)', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.path, waterLevel: 0.6));

      final drained = world.drainWaterAt(0, 0, ZLevel.surface, 0.2);

      expect(drained, 0.2);
      expect(world.tileAt(0, 0, ZLevel.surface).waterLevel, closeTo(0.4, 1e-9));
    });

    test('amount größer als vorhandenes Wasser klemmt auf den verfügbaren Rest', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.path, waterLevel: 0.1));

      final drained = world.drainWaterAt(0, 0, ZLevel.surface, 5.0);

      expect(drained, closeTo(0.1, 1e-9));
      expect(world.tileAt(0, 0, ZLevel.surface).waterLevel, 0);
    });

    test('liefert null auf einem bereits trockenen Tile und ändert nichts', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.grass));

      final drained = world.drainWaterAt(0, 0, ZLevel.surface);

      expect(drained, isNull);
      expect(world.tileAt(0, 0, ZLevel.surface).type, TileType.grass);
      expect(world.tileAt(0, 0, ZLevel.surface).waterLevel, 0);
    });

    test('ändert nie den Tile-Typ, nur den Wasserstand', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.water, waterLevel: 1.0));

      world.drainWaterAt(0, 0, ZLevel.surface, 0.3);

      expect(world.tileAt(0, 0, ZLevel.surface).type, TileType.water);
    });

    test('wirft bei amount <= 0', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.path, waterLevel: 0.5));

      expect(() => world.drainWaterAt(0, 0, ZLevel.surface, 0), throwsA(isA<AssertionError>()));
      expect(() => world.drainWaterAt(0, 0, ZLevel.surface, -1), throwsA(isA<AssertionError>()));
    });
  });
}
