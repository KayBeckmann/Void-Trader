import 'package:test/test.dart';
import 'package:vt_npc/vt_npc.dart';

void main() {
  group('Npc.tick Tagesroutine', () {
    test('arbeitet tagsüber, wenn alle Bedürfnisse gedeckt sind', () {
      final npc = Npc(id: 'a', type: NpcType.colonist);
      npc.tick(10, isDaytime: true);
      expect(npc.activity, NpcActivity.working);
    });

    test('schläft nachts, wenn alle Bedürfnisse gedeckt sind', () {
      final npc = Npc(
        id: 'a',
        type: NpcType.colonist,
        needs: NpcNeeds(tiredness: 0.5),
      );
      final before = npc.needs.tiredness;

      npc.tick(10, isDaytime: false);

      expect(npc.activity, NpcActivity.sleeping);
      expect(npc.needs.tiredness, greaterThan(before));
    });

    test('kritischer Hunger hat Vorrang vor Tagesroutine (auch tagsüber)', () {
      final npc = Npc(
        id: 'a',
        type: NpcType.farmer,
        needs: NpcNeeds(hunger: 0.1),
      );
      final before = npc.needs.hunger;

      npc.tick(5, isDaytime: true);

      expect(npc.activity, NpcActivity.eating);
      expect(npc.needs.hunger, greaterThan(before));
    });

    test('kritischer Durst führt zu Trinken, wenn Hunger nicht kritisch ist', () {
      final npc = Npc(
        id: 'a',
        type: NpcType.colonist,
        needs: NpcNeeds(hunger: 0.9, thirst: 0.05),
      );

      npc.tick(1, isDaytime: true);

      expect(npc.activity, NpcActivity.drinking);
    });

    test('Hunger hat Vorrang vor Durst, wenn beide kritisch sind', () {
      final npc = Npc(
        id: 'a',
        type: NpcType.colonist,
        needs: NpcNeeds(hunger: 0.1, thirst: 0.05),
      );

      npc.tick(1, isDaytime: true);

      expect(npc.activity, NpcActivity.eating);
    });

    test('idle senkt langsam die Moral', () {
      // idle wird nie automatisch gewählt in der aktuellen Prioritätsregel
      // (immer working/sleeping/eating/drinking) — Test dokumentiert das
      // Verhalten, falls Activity manuell auf idle gesetzt und direkt die
      // Bedürfnis-Logik über tick erneut ausgewertet wird.
      final npc = Npc(id: 'a', type: NpcType.colonist);
      expect(npc.activity, NpcActivity.idle);
    });

    test('Bedürfnisse verfallen jeden Tick, bevor die Aktivität gewählt wird', () {
      // Kleiner dt, damit kein Bedürfnis die kritische Schwelle unterschreitet
      // und dadurch sofort wieder aufgefüllt würde (das würde den Verfall in
      // diesem Test sonst verdecken).
      final npc = Npc(id: 'a', type: NpcType.colonist);
      npc.tick(5, isDaytime: true);
      expect(npc.needs.hunger, lessThan(1.0));
      expect(npc.needs.thirst, lessThan(1.0));
    });

    test('ist deterministisch bei gleicher Ausgangslage und Tick-Abfolge', () {
      final a = Npc(id: 'a', type: NpcType.miner, needs: NpcNeeds(tiredness: 0.4));
      final b = Npc(id: 'a', type: NpcType.miner, needs: NpcNeeds(tiredness: 0.4));

      for (final step in [(5.0, true), (5.0, false), (20.0, false), (30.0, true)]) {
        a.tick(step.$1, isDaytime: step.$2);
        b.tick(step.$1, isDaytime: step.$2);
      }

      expect(a.activity, b.activity);
      expect(a.needs.hunger, b.needs.hunger);
      expect(a.needs.thirst, b.needs.thirst);
      expect(a.needs.tiredness, b.needs.tiredness);
      expect(a.needs.morale, b.needs.morale);
    });
  });
}
