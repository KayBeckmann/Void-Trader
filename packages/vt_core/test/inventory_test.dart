import 'package:test/test.dart';
import 'package:vt_core/vt_core.dart';

void main() {
  group('Inventory', () {
    test('count ist 0 für nie hinzugefügte Ressourcen', () {
      final inventory = Inventory();
      expect(inventory.count(Resource.stone), 0);
    });

    test('add erhöht die Menge', () {
      final inventory = Inventory();
      inventory.add(Resource.stone, 3);
      inventory.add(Resource.stone, 2);
      expect(inventory.count(Resource.stone), 5);
    });

    test('has prüft die vorhandene Menge korrekt', () {
      final inventory = Inventory();
      inventory.add(Resource.ore, 4);
      expect(inventory.has(Resource.ore, 4), isTrue);
      expect(inventory.has(Resource.ore, 5), isFalse);
      expect(inventory.has(Resource.ore, 0), isTrue);
    });

    test('remove verringert die Menge', () {
      final inventory = Inventory();
      inventory.add(Resource.stone, 5);
      inventory.remove(Resource.stone, 2);
      expect(inventory.count(Resource.stone), 3);
    });

    test('remove wirft bei nicht ausreichender Menge und ändert nichts', () {
      final inventory = Inventory();
      inventory.add(Resource.stone, 1);
      expect(() => inventory.remove(Resource.stone, 5), throwsStateError);
      expect(inventory.count(Resource.stone), 1);
    });

    test('hasAll prüft mehrere Ressourcen gleichzeitig', () {
      final inventory = Inventory();
      inventory.add(Resource.stone, 3);
      inventory.add(Resource.ore, 1);

      expect(inventory.hasAll({Resource.stone: 2, Resource.ore: 1}), isTrue);
      expect(inventory.hasAll({Resource.stone: 2, Resource.ore: 2}), isFalse);
    });

    test('removeAll zieht alles auf einmal ab', () {
      final inventory = Inventory();
      inventory.add(Resource.stone, 3);
      inventory.add(Resource.ore, 2);

      inventory.removeAll({Resource.stone: 2, Resource.ore: 1});

      expect(inventory.count(Resource.stone), 1);
      expect(inventory.count(Resource.ore), 1);
    });

    test('removeAll ist alles-oder-nichts: wirft ohne Teilabzug', () {
      final inventory = Inventory();
      inventory.add(Resource.stone, 3);
      inventory.add(Resource.ore, 1);

      expect(
        () => inventory.removeAll({Resource.stone: 2, Resource.ore: 5}),
        throwsStateError,
      );

      // Nichts wurde abgezogen, obwohl "stone" allein ausgereicht hätte.
      expect(inventory.count(Resource.stone), 3);
      expect(inventory.count(Resource.ore), 1);
    });

    test('snapshot ist unveränderlich', () {
      final inventory = Inventory();
      inventory.add(Resource.stone, 1);
      final snapshot = inventory.snapshot;
      expect(() => snapshot[Resource.stone] = 99, throwsUnsupportedError);
    });
  });
}
