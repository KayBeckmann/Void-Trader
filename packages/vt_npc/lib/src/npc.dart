import 'npc_needs.dart';
import 'npc_type.dart';

/// Aktuelle Tätigkeit eines NPCs (Roadmap Phase 5: NPC-Verhalten V1).
enum NpcActivity { idle, working, eating, drinking, sleeping }

/// Ein einzelner NPC mit Bedürfnissen und einfacher Tagesroutine.
///
/// [tick] wählt die Aktivität nach einer festen Prioritätsregel: kritische
/// Grundbedürfnisse zuerst, danach Nachtruhe, danach Arbeit, sonst
/// Leerlauf. Bewusst ohne Pfadfindung/Bewegung — das lebt in der
/// Flame-Schicht, hier geht es nur um den inneren Zustand.
class Npc {
  final String id;
  final NpcType type;
  final NpcNeeds needs;
  NpcActivity activity;

  Npc({required this.id, required this.type, NpcNeeds? needs, this.activity = NpcActivity.idle})
    : needs = needs ?? NpcNeeds();

  static const double _criticalThreshold = 0.2;
  static const double _eatRate = 0.2;
  static const double _drinkRate = 0.25;
  static const double _sleepRate = 0.15;
  static const double _workMoraleRate = 0.002;
  static const double _idleMoraleDecayRate = 0.001;

  /// Ein Simulationsschritt: Bedürfnisse verfallen, die Aktivität wird neu
  /// gewählt und wirkt anschließend auf die Bedürfnisse zurück.
  void tick(double dtSeconds, {required bool isDaytime}) {
    if (dtSeconds <= 0) return;

    needs.decay(dtSeconds);
    activity = _chooseActivity(isDaytime);

    switch (activity) {
      case NpcActivity.eating:
        needs.eat(_eatRate * dtSeconds);
        break;
      case NpcActivity.drinking:
        needs.drink(_drinkRate * dtSeconds);
        break;
      case NpcActivity.sleeping:
        needs.sleep(_sleepRate * dtSeconds);
        break;
      case NpcActivity.working:
        needs.adjustMorale(_workMoraleRate * dtSeconds);
        break;
      case NpcActivity.idle:
        needs.adjustMorale(-_idleMoraleDecayRate * dtSeconds);
        break;
    }
  }

  NpcActivity _chooseActivity(bool isDaytime) {
    // Kritische Grundbedürfnisse haben Vorrang vor Tagesroutine und Arbeit.
    if (needs.hunger < _criticalThreshold) return NpcActivity.eating;
    if (needs.thirst < _criticalThreshold) return NpcActivity.drinking;
    if (needs.tiredness < _criticalThreshold) return NpcActivity.sleeping;

    if (!isDaytime) return NpcActivity.sleeping;

    return NpcActivity.working;
  }
}
