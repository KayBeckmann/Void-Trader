import 'package:flutter_test/flutter_test.dart';
import 'package:vt_physics/vt_physics.dart';
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

  group('DebugMapComponent Konstruktion', () {
    test('akzeptiert ein FluidGrid in Fenstergröße', () {
      final world = vt_world.World(1);
      final fluidGrid = FluidGrid(20, 10);

      final component = DebugMapComponent(
        gameWorld: world,
        originX: -5,
        originY: -5,
        tileWidth: 20,
        tileHeight: 10,
        z: vt_world.ZLevel.surface,
        fluidGrid: fluidGrid,
      );

      expect(component.size.x, 20 * component.tileSize);
      expect(component.size.y, 10 * component.tileSize);
    });

    test('wirft bei abweichender FluidGrid-Größe', () {
      final world = vt_world.World(1);
      final wrongGrid = FluidGrid(4, 4);

      expect(
        () => DebugMapComponent(
          gameWorld: world,
          originX: 0,
          originY: 0,
          tileWidth: 32,
          tileHeight: 32,
          z: vt_world.ZLevel.surface,
          fluidGrid: wrongGrid,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
