import 'package:flutter_test/flutter_test.dart';
import 'package:vt_physics/vt_physics.dart';
import 'package:vt_world/vt_world.dart';
import 'package:void_trader/game/debug_map_component.dart';

void main() {
  group('DebugMapComponent.tileColor', () {
    test('liefert für jeden TileType eine Farbe', () {
      for (final type in TileType.values) {
        expect(DebugMapComponent.tileColor(type), isNotNull);
      }
    });
  });

  group('DebugMapComponent Konstruktion', () {
    test('akzeptiert ein FluidGrid in Chunk-Größe', () {
      final world = World(1);
      final fluidGrid = FluidGrid(Chunk.size, Chunk.size);

      final component = DebugMapComponent(
        world: world,
        chunkCoord: const ChunkCoord(0, 0),
        z: ZLevel.surface,
        fluidGrid: fluidGrid,
      );

      expect(component.size.x, Chunk.size * component.tileSize);
      expect(component.size.y, Chunk.size * component.tileSize);
    });

    test('wirft bei abweichender FluidGrid-Größe', () {
      final world = World(1);
      final wrongGrid = FluidGrid(4, 4);

      expect(
        () => DebugMapComponent(
          world: world,
          chunkCoord: const ChunkCoord(0, 0),
          z: ZLevel.surface,
          fluidGrid: wrongGrid,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
