import 'package:test/test.dart';
import 'package:vt_core/vt_core.dart';

void main() {
  group('Ship', () {
    test('startet mit einer Treibstoff-Reserve, sonst leerem Frachtraum', () {
      final ship = Ship();
      expect(ship.cargo.snapshot, {Resource.fuel: Ship.startingFuel});
    });

    test('Treibstoff und Credits belegen keinen Laderaum', () {
      final ship = Ship();
      ship.cargo.add(Resource.credits, 500);
      ship.cargo.add(Resource.fuel, 100);

      expect(ship.cargoUsed, 0);
      expect(ship.freeCargoSpace, Ship.cargoCapacity);
    });

    test('Fracht belegt Laderaum, freier Platz sinkt und wird nie negativ', () {
      final ship = Ship();
      ship.cargo.add(Resource.stone, 20);
      ship.cargo.add(Resource.ore, 5);

      expect(ship.cargoUsed, 25);
      expect(ship.freeCargoSpace, Ship.cargoCapacity - 25);

      ship.cargo.add(Resource.stone, Ship.cargoCapacity);
      expect(ship.freeCargoSpace, 0);
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
