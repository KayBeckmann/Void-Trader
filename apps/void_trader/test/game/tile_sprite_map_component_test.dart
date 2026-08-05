import 'package:flutter_test/flutter_test.dart';
import 'package:vt_world/vt_world.dart' as vt_world;
import 'package:void_trader/game/tile_sprite_map_component.dart';

void main() {
  group('TileSpriteMapComponent.tileAssetFiles', () {
    test('enthält für jeden TileType eine Sprite-Datei', () {
      for (final type in vt_world.TileType.values) {
        expect(
          TileSpriteMapComponent.tileAssetFiles.containsKey(type),
          isTrue,
          reason: '$type fehlt im Sprite-Mapping',
        );
      }
    });

    test('alle Dateien liegen unter tiles/', () {
      for (final file in TileSpriteMapComponent.tileAssetFiles.values) {
        expect(file, startsWith('tiles/'));
      }
    });
  });

  group('TileSpriteMapComponent Konstruktion', () {
    test('Größe ergibt sich aus tileWidth/tileHeight * tileSize', () {
      final world = vt_world.World(1);

      final component = TileSpriteMapComponent(
        gameWorld: world,
        originX: -5,
        originY: -5,
        tileWidth: 10,
        tileHeight: 6,
        z: vt_world.ZLevel.surface,
        tileSize: 32,
      );

      expect(component.size.x, 10 * 32);
      expect(component.size.y, 6 * 32);
    });
  });
}
