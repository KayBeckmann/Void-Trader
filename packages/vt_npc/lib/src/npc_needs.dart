/// Grundbedürfnisse eines NPCs (Roadmap Phase 5: NPC-Zustände).
///
/// Alle Werte liegen in `[0, 1]`: `1` = vollständig gedeckt, `0` = kritisch.
/// Sauerstoff/Sicherheit und Vertrauen/Ruf sind laut Roadmap zwar auch
/// NPC-Zustände, brauchen aber erst eine Umgebungs- bzw. Beziehungs-
/// Anbindung und kommen mit einem späteren Schritt dazu — V1 startet mit
/// den vier Grundwerten, die eine einfache Tagesroutine bereits tragen.
class NpcNeeds {
  double hunger;
  double thirst;
  double tiredness;
  double morale;

  NpcNeeds({
    this.hunger = 1.0,
    this.thirst = 1.0,
    this.tiredness = 1.0,
    this.morale = 1.0,
  }) : assert(_inRange(hunger), 'hunger muss in [0,1] liegen'),
       assert(_inRange(thirst), 'thirst muss in [0,1] liegen'),
       assert(_inRange(tiredness), 'tiredness muss in [0,1] liegen'),
       assert(_inRange(morale), 'morale muss in [0,1] liegen');

  static bool _inRange(double v) => v >= 0 && v <= 1;

  static double _clamp(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  /// Lässt Hunger/Durst/Müdigkeit über die Zeit verfallen. Moral verfällt
  /// bewusst nicht automatisch — sie wird durch Aktivitäten/Ereignisse
  /// beeinflusst (siehe [Npc]).
  void decay(
    double dtSeconds, {
    double hungerRate = 0.01,
    double thirstRate = 0.015,
    double tirednessRate = 0.008,
  }) {
    if (dtSeconds <= 0) return;
    hunger = _clamp(hunger - hungerRate * dtSeconds);
    thirst = _clamp(thirst - thirstRate * dtSeconds);
    tiredness = _clamp(tiredness - tirednessRate * dtSeconds);
  }

  void eat(double amount) => hunger = _clamp(hunger + amount);

  void drink(double amount) => thirst = _clamp(thirst + amount);

  void sleep(double amount) => tiredness = _clamp(tiredness + amount);

  void adjustMorale(double delta) => morale = _clamp(morale + delta);

  /// Ob mindestens ein Grundbedürfnis kritisch niedrig ist.
  bool get isCritical => hunger < 0.15 || thirst < 0.15 || tiredness < 0.1;
}
