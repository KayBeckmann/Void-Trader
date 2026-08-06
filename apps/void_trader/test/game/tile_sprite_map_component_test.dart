import 'package:flame/components.dart';
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
    test('lässt sich mit einem centerProvider erstellen', () {
      final world = vt_world.World(1);

      final component = TileSpriteMapComponent(
        gameWorld: world,
        centerProvider: () => Vector2.zero(),
        viewRadiusTiles: 10,
        zProvider: () => vt_world.ZLevel.surface,
        tileSize: 32,
      );

      expect(component.viewRadiusTiles, 10);
      expect(component.tileSize, 32);
    });

    test('wirft bei nicht-positivem viewRadiusTiles', () {
      final world = vt_world.World(1);

      expect(
        () => TileSpriteMapComponent(
          gameWorld: world,
          centerProvider: () => Vector2.zero(),
          viewRadiusTiles: -1,
          zProvider: () => vt_world.ZLevel.surface,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
