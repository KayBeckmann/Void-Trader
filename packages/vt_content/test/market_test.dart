import 'package:test/test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';

void main() {
  group('sellResource', () {
    test('verkauft zum hinterlegten Preis und legt Credits ins Inventar', () {
      final inventory = Inventory();
      inventory.add(Resource.stone, 5);

      final earned = sellResource(inventory, Resource.stone, 3);

      expect(earned, 3 * sellPrices[Resource.stone]!);
      expect(inventory.count(Resource.stone), 2);
      expect(inventory.count(Resource.credits), earned);
    });

    test('liefert null und ändert nichts bei nicht handelbarer Ressource', () {
      final inventory = Inventory();
      inventory.add(Resource.credits, 10);

      final earned = sellResource(inventory, Resource.credits, 1);

      expect(earned, isNull);
      expect(inventory.count(Resource.credits), 10);
    });

    test('liefert null und ändert nichts bei zu wenig Bestand', () {
      final inventory = Inventory();
      inventory.add(Resource.ore, 1);

      final earned = sellResource(inventory, Resource.ore, 5);

      expect(earned, isNull);
      expect(inventory.count(Resource.ore), 1);
      expect(inventory.count(Resource.credits), 0);
    });

    test('liefert null bei amount <= 0', () {
      final inventory = Inventory();
      inventory.add(Resource.stone, 5);
      expect(sellResource(inventory, Resource.stone, 0), isNull);
      expect(sellResource(inventory, Resource.stone, -1), isNull);
    });

    test('jede handelbare Ressource hat einen positiven Preis', () {
      for (final price in sellPrices.values) {
        expect(price, greaterThan(0));
      }
      expect(sellPrices.containsKey(Resource.credits), isFalse);
    });
  });

  group('BuildingType.market', () {
    test('hat eine Definition mit Baukosten', () {
      final market = buildingDefinitionFor(BuildingType.market);
      expect(market.buildCost, isNotEmpty);
    });
  });
}
