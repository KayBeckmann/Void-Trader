import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

/// Roadmap-Sofort-Korrektur "Bewegung, Kollision, Startzone und Sicht/Fog
/// of War", Teil MOV-03: Rampen-Tiles verbinden Oberfläche und Hügel an
/// derselben Welt-Koordinate.
void main() {
  group('TileType.slope', () {
    test('ist begehbar und blockiert keine Sicht', () {
      expect(TileType.slope.blocksMovement, isFalse);
      expect(TileType.slope.blocksSight, isFalse);
      expect(const Tile(TileType.slope).isWalkable, isTrue);
    });

    test('ist nicht abbaubar', () {
      expect(TileType.slope.isMinable, isFalse);
    });
  });

  group('World-Generation Rampen-Spiegelung (Roadmap MOV-03)', () {
    test('eine bekannte Rampe existiert an derselben Koordinate auf beiden Ebenen', () {
      final world = World(1);

      expect(world.tileAt(-18, 37, ZLevel.surface).type, TileType.slope);
      expect(world.tileAt(-18, 37, ZLevel.hills).type, TileType.slope);
    });

    test('jede Oberflächen-Rampe hat eine passende Rampe auf der Hügel-Ebene', () {
      for (final seed in [1, 42, 999]) {
        final world = World(seed);
        var foundAny = false;

        for (var x = -60; x <= 60; x++) {
          for (var y = -60; y <= 60; y++) {
            if (world.tileAt(x, y, ZLevel.surface).type != TileType.slope) continue;
            foundAny = true;
            expect(
              world.tileAt(x, y, ZLevel.hills).type,
              TileType.slope,
              reason: 'Seed $seed: Rampe bei ($x,$y) fehlt auf der Hügel-Ebene',
            );
          }
        }

        expect(foundAny, isTrue, reason: 'Seed $seed: keine Rampe im Suchbereich gefunden');
      }
    });

    test('Rampen liegen nie in der sicheren Startzone', () {
      final world = World(1);
      for (var x = -4; x <= 4; x++) {
        for (var y = -4; y <= 4; y++) {
          expect(world.tileAt(x, y, ZLevel.surface).type, isNot(TileType.slope));
        }
      }
    });
  });
}
