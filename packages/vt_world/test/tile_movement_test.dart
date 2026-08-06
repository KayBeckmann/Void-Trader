import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('TileMovement.blocksMovement', () {
    test('Wasser und Wald blockieren Bewegung, obwohl sie nicht solide sind', () {
      expect(TileType.water.blocksMovement, isTrue);
      expect(TileType.forest.blocksMovement, isTrue);
      expect(const Tile(TileType.water).isSolid, isFalse);
      expect(const Tile(TileType.forest).isSolid, isFalse);
    });

    test('physisch festes Gestein blockiert weiterhin', () {
      for (final type in [TileType.stone, TileType.rockWall, TileType.ore]) {
        expect(type.blocksMovement, isTrue, reason: '$type sollte blockieren');
      }
    });

    test('begehbare Tiles blockieren nicht', () {
      for (final type in [
        TileType.grass,
        TileType.dirt,
        TileType.farmland,
        TileType.path,
        TileType.empty,
        TileType.caveEntrance,
      ]) {
        expect(type.blocksMovement, isFalse, reason: '$type sollte nicht blockieren');
      }
    });

    test('Tile.isWalkable spiegelt blocksMovement', () {
      expect(const Tile(TileType.water).isWalkable, isFalse);
      expect(const Tile(TileType.forest).isWalkable, isFalse);
      expect(const Tile(TileType.grass).isWalkable, isTrue);
    });
  });

  group('TileMovement.blocksSight', () {
    test('Wasser blockiert Bewegung, aber nicht die Sicht', () {
      expect(TileType.water.blocksMovement, isTrue);
      expect(TileType.water.blocksSight, isFalse);
    });

    test('Wald und Fels blockieren auch die Sicht', () {
      for (final type in [TileType.forest, TileType.stone, TileType.rockWall, TileType.ore]) {
        expect(type.blocksSight, isTrue, reason: '$type sollte Sicht blockieren');
      }
    });
  });

  group('TileMovement.movementBlockedReason', () {
    test('liefert je Hindernistyp eine eigene deutsche Meldung', () {
      expect(TileType.water.movementBlockedReason, contains('Wasser'));
      expect(TileType.forest.movementBlockedReason, contains('Baum'));
      expect(TileType.stone.movementBlockedReason, contains('Felswand'));
      expect(TileType.rockWall.movementBlockedReason, contains('Felswand'));
    });

    test('ist null für begehbare Tiles', () {
      expect(TileType.grass.movementBlockedReason, isNull);
      expect(TileType.path.movementBlockedReason, isNull);
    });
  });
}
