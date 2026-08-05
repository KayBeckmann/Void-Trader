import 'package:flutter_test/flutter_test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_world/vt_world.dart' as vt_world;
import 'package:void_trader/game/debug_map_component.dart';

void main() {
  group('DebugMapComponent.tileColor', () {
    test('liefert für jeden TileType eine Farbe', () {
      for (final type in vt_world.TileType.values) {
        expect(DebugMapComponent.tileColor(type), isNotNull);
      }
    });
  });

  group('DebugMapComponent.buildingColor', () {
    test('liefert für jeden BuildingType eine Farbe', () {
      for (final type in BuildingType.values) {
        expect(DebugMapComponent.buildingColor(type), isNotNull);
      }
    });
  });

  group('DebugMapComponent Konstruktion', () {
    test('Größe ergibt sich aus tileWidth/tileHeight * tileSize', () {
      final world = vt_world.World(1);

      final component = DebugMapComponent(
        gameWorld: world,
        originX: -5,
        originY: -5,
        tileWidth: 20,
        tileHeight: 10,
        z: vt_world.ZLevel.surface,
      );

      expect(component.size.x, 20 * component.tileSize);
      expect(component.size.y, 10 * component.tileSize);
    });
  });
}
