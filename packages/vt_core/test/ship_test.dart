import 'package:test/test.dart';
import 'package:vt_core/vt_core.dart';

void main() {
  group('Ship', () {
    test('hat einen eigenen, leeren Frachtraum', () {
      final ship = Ship();
      expect(ship.cargo.snapshot, isEmpty);
    });

    test('Frachtraum ist unabhängig von anderen Inventaren', () {
      final ship = Ship();
      final playerInventory = Inventory();
      playerInventory.add(Resource.stone, 5);

      expect(ship.cargo.count(Resource.stone), 0);

      ship.cargo.add(Resource.stone, 3);
      expect(playerInventory.count(Resource.stone), 5);
      expect(ship.cargo.count(Resource.stone), 3);
    });
  });
}
