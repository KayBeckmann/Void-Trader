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

  group('stationSellPrices (Roadmap Phase 9 V4)', () {
    test('listet dieselben Ressourcen wie sellPrices', () {
      expect(stationSellPrices.keys.toSet(), sellPrices.keys.toSet());
    });

    test('jeder Stationspreis ist höher als der Planet-Marktpreis', () {
      for (final resource in stationSellPrices.keys) {
        expect(
          stationSellPrices[resource],
          greaterThan(sellPrices[resource]!),
          reason:
              '$resource sollte an der Station mehr wert sein als auf dem Planeten',
        );
      }
    });
  });

  group('stationBuyPrices (Roadmap Phase 9 V8)', () {
    test('listet mindestens dieselben Ressourcen wie stationSellPrices', () {
      expect(
        stationBuyPrices.keys.toSet().containsAll(stationSellPrices.keys),
        isTrue,
      );
    });

    test(
      'jeder Ankaufpreis liegt über dem zugehörigen Stationsverkaufspreis',
      () {
        for (final resource in stationSellPrices.keys) {
          expect(
            stationBuyPrices[resource],
            greaterThan(stationSellPrices[resource]!),
            reason:
                '$resource: Kaufen-und-Zurückverkaufen darf kein Gewinn sein',
          );
        }
      },
    );

    test(
      'Treibstoff ist seit Roadmap V9 zusätzlich käuflich, aber nicht verkäuflich',
      () {
        expect(stationBuyPrices, contains(Resource.fuel));
        expect(stationSellPrices, isNot(contains(Resource.fuel)));
        expect(sellPrices, isNot(contains(Resource.fuel)));
      },
    );
  });

  group('stationBuyBundle (Roadmap Phase 9 V8)', () {
    test('listet dieselben Ressourcen wie stationBuyPrices', () {
      expect(stationBuyBundle.keys.toSet(), stationBuyPrices.keys.toSet());
    });

    test('jede Bündelmenge ist positiv', () {
      for (final amount in stationBuyBundle.values) {
        expect(amount, greaterThan(0));
      }
    });
  });

  group('BuildingType.market', () {
    test('hat eine Definition mit Baukosten', () {
      final market = buildingDefinitionFor(BuildingType.market);
      expect(market.buildCost, isNotEmpty);
    });
  });
}
