import 'package:flame/components.dart';
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
    test('enabled ist standardmäßig aus (Overlay statt Standardansicht)', () {
      final world = vt_world.World(1);

      final component = DebugMapComponent(
        gameWorld: world,
        centerProvider: () => Vector2.zero(),
        viewRadiusTiles: 4,
        zProvider: () => vt_world.ZLevel.surface,
      );

      expect(component.enabled, isFalse);
      component.enabled = true;
      expect(component.enabled, isTrue);
    });

    test('wirft bei nicht-positivem viewRadiusTiles', () {
      final world = vt_world.World(1);

      expect(
        () => DebugMapComponent(
          gameWorld: world,
          centerProvider: () => Vector2.zero(),
          viewRadiusTiles: 0,
          zProvider: () => vt_world.ZLevel.surface,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
