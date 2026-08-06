import 'package:test/test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';

void main() {
  group('BuildingDefinition', () {
    test('jeder BuildingType hat eine Definition', () {
      for (final type in BuildingType.values) {
        expect(buildingDefinitions.containsKey(type), isTrue, reason: '$type fehlt');
      }
    });

    test('buildingDefinitionFor liefert die passende Definition', () {
      final wall = buildingDefinitionFor(BuildingType.wall);
      expect(wall.type, BuildingType.wall);
      expect(wall.buildCost, {Resource.stone: 3});
    });

    test('Baukosten sind nie leer', () {
      for (final definition in buildingDefinitions.values) {
        expect(definition.buildCost, isNotEmpty, reason: '${definition.name} hat keine Kosten');
      }
    });
  });

  group('BuildingMovement', () {
    test('jedes Gebäude blockiert die Bewegung (Roadmap MOV-01)', () {
      for (final type in BuildingType.values) {
        expect(type.blocksMovement, isTrue, reason: '$type sollte blockieren');
      }
    });
  });
}
