import 'package:test/test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('World Gebäude-Platzierung', () {
    test('platziert ein Gebäude auf einem begehbaren Tile', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.grass));

      final success = world.placeBuildingAt(0, 0, ZLevel.surface, BuildingType.wall);

      expect(success, isTrue);
      expect(world.buildingAt(0, 0, ZLevel.surface), BuildingType.wall);
    });

    test('verweigert Platzierung auf soliden Tiles', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.stone));

      final success = world.placeBuildingAt(0, 0, ZLevel.surface, BuildingType.wall);

      expect(success, isFalse);
      expect(world.buildingAt(0, 0, ZLevel.surface), isNull);
    });

    test('verweigert Platzierung auf bereits belegtem Tile', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.grass));
      world.placeBuildingAt(0, 0, ZLevel.surface, BuildingType.wall);

      final second = world.placeBuildingAt(0, 0, ZLevel.surface, BuildingType.workbench);

      expect(second, isFalse);
      expect(world.buildingAt(0, 0, ZLevel.surface), BuildingType.wall);
    });

    test('buildingAt liefert null ohne Platzierung', () {
      final world = World(1);
      expect(world.buildingAt(0, 0, ZLevel.surface), isNull);
    });

    test('removeBuildingAt entfernt ein Gebäude und meldet Erfolg', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.grass));
      world.placeBuildingAt(0, 0, ZLevel.surface, BuildingType.wall);

      final removed = world.removeBuildingAt(0, 0, ZLevel.surface);

      expect(removed, isTrue);
      expect(world.buildingAt(0, 0, ZLevel.surface), isNull);
    });

    test('removeBuildingAt meldet false, wenn nichts zu entfernen war', () {
      final world = World(1);
      expect(world.removeBuildingAt(5, 5, ZLevel.surface), isFalse);
    });

    test('Gebäude an unterschiedlichen Koordinaten/Ebenen beeinflussen sich nicht', () {
      final world = World(1);
      world.setTileAt(0, 0, ZLevel.surface, const Tile(TileType.grass));
      world.setTileAt(0, 0, ZLevel.cellar, const Tile(TileType.dirt));

      world.placeBuildingAt(0, 0, ZLevel.surface, BuildingType.wall);
      world.placeBuildingAt(0, 0, ZLevel.cellar, BuildingType.workbench);

      expect(world.buildingAt(0, 0, ZLevel.surface), BuildingType.wall);
      expect(world.buildingAt(0, 0, ZLevel.cellar), BuildingType.workbench);
    });
  });
}
