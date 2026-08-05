import 'package:flutter_test/flutter_test.dart';
import 'package:void_trader/game/tile_highlight_component.dart';

void main() {
  group('TileHighlightComponent', () {
    test('lässt sich mit einem tileProvider erstellen', () {
      final component = TileHighlightComponent(
        tileProvider: () => (x: 0, y: 0),
        tileSize: 32,
      );

      expect(component.tileSize, 32);
    });

    test('tileProvider steuert, ob überhaupt etwas hervorgehoben wird', () {
      ({int x, int y})? tile;
      final component = TileHighlightComponent(
        tileProvider: () => tile,
        tileSize: 32,
      );

      expect(component.tileProvider(), isNull);
      tile = (x: 3, y: 4);
      expect(component.tileProvider(), (x: 3, y: 4));
    });
  });
}
