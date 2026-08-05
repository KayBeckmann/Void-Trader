import 'package:test/test.dart';
import 'package:vt_npc/vt_npc.dart';

void main() {
  group('NpcNeeds', () {
    test('startet standardmäßig vollständig gedeckt', () {
      final needs = NpcNeeds();
      expect(needs.hunger, 1.0);
      expect(needs.thirst, 1.0);
      expect(needs.tiredness, 1.0);
      expect(needs.morale, 1.0);
    });

    test('wirft bei Werten außerhalb von [0,1]', () {
      expect(() => NpcNeeds(hunger: 1.5), throwsA(isA<AssertionError>()));
      expect(() => NpcNeeds(thirst: -0.1), throwsA(isA<AssertionError>()));
    });

    test('decay verringert Hunger/Durst/Müdigkeit über die Zeit', () {
      final needs = NpcNeeds();
      needs.decay(10, hungerRate: 0.01, thirstRate: 0.02, tirednessRate: 0.005);

      expect(needs.hunger, closeTo(0.9, 1e-9));
      expect(needs.thirst, closeTo(0.8, 1e-9));
      expect(needs.tiredness, closeTo(0.95, 1e-9));
      expect(needs.morale, 1.0); // verfällt nicht automatisch
    });

    test('decay klemmt am unteren Rand bei 0', () {
      final needs = NpcNeeds(hunger: 0.05);
      needs.decay(100, hungerRate: 0.01);
      expect(needs.hunger, 0.0);
    });

    test('eat/drink/sleep erhöhen die jeweiligen Werte, geklemmt bei 1', () {
      final needs = NpcNeeds(hunger: 0.5, thirst: 0.5, tiredness: 0.5);
      needs.eat(0.3);
      needs.drink(0.3);
      needs.sleep(0.3);

      expect(needs.hunger, closeTo(0.8, 1e-9));
      expect(needs.thirst, closeTo(0.8, 1e-9));
      expect(needs.tiredness, closeTo(0.8, 1e-9));

      needs.eat(1.0);
      expect(needs.hunger, 1.0);
    });

    test('adjustMorale erhöht/verringert und klemmt in [0,1]', () {
      final needs = NpcNeeds(morale: 0.5);
      needs.adjustMorale(0.2);
      expect(needs.morale, closeTo(0.7, 1e-9));

      needs.adjustMorale(-1.0);
      expect(needs.morale, 0.0);
    });

    test('isCritical erkennt kritisch niedrige Grundbedürfnisse', () {
      expect(NpcNeeds().isCritical, isFalse);
      expect(NpcNeeds(hunger: 0.1).isCritical, isTrue);
      expect(NpcNeeds(thirst: 0.1).isCritical, isTrue);
      expect(NpcNeeds(tiredness: 0.05).isCritical, isTrue);
      // Moral allein macht nicht kritisch (kein Grundbedürfnis).
      expect(NpcNeeds(morale: 0.0).isCritical, isFalse);
    });
  });
}
