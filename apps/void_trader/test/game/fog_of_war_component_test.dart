import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_world/vt_world.dart' as vt_world;
import 'package:void_trader/game/fog_of_war_component.dart';

void main() {
  group('FogOfWarComponent Konstruktion', () {
    test('lässt sich mit einem ExplorationTracker erstellen', () {
      final tracker = vt_world.ExplorationTracker();

      final component = FogOfWarComponent(
        explorationTracker: tracker,
        centerProvider: () => Vector2.zero(),
        viewRadiusTiles: 4,
      );

      expect(component.viewRadiusTiles, 4);
      expect(component.explorationTracker, same(tracker));
    });

    test('wirft bei nicht-positivem viewRadiusTiles', () {
      final tracker = vt_world.ExplorationTracker();

      expect(
        () => FogOfWarComponent(
          explorationTracker: tracker,
          centerProvider: () => Vector2.zero(),
          viewRadiusTiles: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('greift auf den übergebenen ExplorationTracker zu', () {
      final tracker = vt_world.ExplorationTracker();
      final component = FogOfWarComponent(
        explorationTracker: tracker,
        centerProvider: () => Vector2.zero(),
        viewRadiusTiles: 2,
      );

      // render() ohne echtes Canvas ist in einem reinen Unit-Test nicht
      // sinnvoll aufrufbar — dieser Test deckt bewusst nur die
      // Konstruktions-/Feldzugriffs-Seite ab, das Rendering selbst läuft
      // über den Browser-Smoke-Test (siehe Bautagebuch/Webpreview).
      expect(component.explorationTracker.stateAt(0, 0), vt_world.VisibilityState.unseen);
    });
  });
}
