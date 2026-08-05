import 'package:flutter_test/flutter_test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:void_trader/ui/objective.dart';

void main() {
  group('buildObjectives', () {
    test('alle Ziele offen bei Spielbeginn', () {
      final objectives = buildObjectives(
        stoneCount: 0,
        builtBuildingTypes: {},
        totalCrafted: 0,
        cargoEverLoaded: false,
      );

      expect(objectives, hasLength(5));
      expect(objectives.every((o) => !o.isComplete), isTrue);
    });

    test('Ziele schalten einzeln um, sobald ihre Bedingung erfüllt ist', () {
      final objectives = buildObjectives(
        stoneCount: 3,
        builtBuildingTypes: {BuildingType.workbench, BuildingType.landingPad},
        totalCrafted: 1,
        cargoEverLoaded: true,
      );

      expect(objectives.every((o) => o.isComplete), isTrue);
    });

    test('Stein-Ziel braucht mindestens 3, nicht weniger', () {
      final objectives = buildObjectives(
        stoneCount: 2,
        builtBuildingTypes: {},
        totalCrafted: 0,
        cargoEverLoaded: false,
      );

      expect(objectives.first.isComplete, isFalse);
    });
  });
}
