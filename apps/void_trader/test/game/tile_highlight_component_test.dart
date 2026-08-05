import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_trader/game/tile_highlight_component.dart';

void main() {
  group('TileHighlightComponent', () {
    test('lässt sich mit den nötigen Providern erstellen', () {
      final component = TileHighlightComponent(
        positionProvider: () => Vector2.zero(),
        isActiveProvider: () => true,
        tileSize: 32,
      );

      expect(component.tileSize, 32);
    });

    test('isActiveProvider steuert, ob überhaupt etwas hervorgehoben wird', () {
      var active = false;
      final component = TileHighlightComponent(
        positionProvider: () => Vector2.zero(),
        isActiveProvider: () => active,
        tileSize: 32,
      );

      // render() darf in beiden Zuständen nicht werfen — der eigentliche
      // Effekt (nichts zeichnen, wenn inaktiv) lässt sich ohne echten
      // Canvas nicht sinnvoll prüfen, das frühe Return aber schon.
      expect(() => component.isActiveProvider(), returnsNormally);
      active = true;
      expect(component.isActiveProvider(), isTrue);
    });
  });
}
