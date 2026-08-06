import 'package:test/test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('World.canEnter/movementBlockReasonAt', () {
    test('erlaubt begehbares, unbelegtes Tile', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.grass));

      expect(world.canEnter(0, 0, ZLevel.surface), isTrue);
      expect(world.movementBlockReasonAt(0, 0, ZLevel.surface), isNull);
    });

    test('blockiert Wasser mit passender deutscher Meldung', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.water));

      expect(world.canEnter(0, 0, ZLevel.surface), isFalse);
      expect(world.movementBlockReasonAt(0, 0, ZLevel.surface), contains('Wasser'));
    });

    test('blockiert ein platziertes Gebäude, selbst auf begehbarem Tile', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.grass));
      world.placeBuildingAt(0, 0, ZLevel.surface, BuildingType.workbench);

      expect(world.canEnter(0, 0, ZLevel.surface), isFalse);
      expect(world.movementBlockReasonAt(0, 0, ZLevel.surface), contains('Gebäude'));
    });

    test('Gebäude-Blockade hat Vorrang vor Tile-Blockade in der Meldung', () {
      // Konstruierter Fall (Platzierung selbst würde das nicht zulassen) —
      // stellt sicher, dass movementBlockReasonAt() nicht zwei Gründe
      // gleichzeitig meldet, sondern deterministisch das Gebäude zuerst prüft.
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.grass));
      world.placeBuildingAt(0, 0, ZLevel.surface, BuildingType.market);

      expect(world.movementBlockReasonAt(0, 0, ZLevel.surface), 'Gebäude blockiert den Weg.');
    });
  });
}
