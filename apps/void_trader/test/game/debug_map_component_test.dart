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
    test('akzeptiert ein FluidGrid in Chunk-Größe', () {
      final world = vt_world.World(1);
      final fluidGrid = FluidGrid(vt_world.Chunk.size, vt_world.Chunk.size);

      final component = DebugMapComponent(
        gameWorld: world,
        chunkCoord: const vt_world.ChunkCoord(0, 0),
        z: vt_world.ZLevel.surface,
        fluidGrid: fluidGrid,
      );

      expect(component.size.x, vt_world.Chunk.size * component.tileSize);
      expect(component.size.y, vt_world.Chunk.size * component.tileSize);
    });

    test('wirft bei abweichender FluidGrid-Größe', () {
      final world = vt_world.World(1);
      final wrongGrid = FluidGrid(4, 4);

      expect(
        () => DebugMapComponent(
          gameWorld: world,
          chunkCoord: const vt_world.ChunkCoord(0, 0),
          z: vt_world.ZLevel.surface,
          fluidGrid: wrongGrid,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
