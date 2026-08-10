/// Aktueller Zustand einer [Drone] (Roadmap Phase 8: "Drohnen sind keine
/// Magie, sondern kleine autonome Arbeitsmaschinen").
enum DroneStatus {
  /// Arbeitet normal, genug Energie vorhanden.
  working,

  /// Arbeitet noch, aber Energie ist knapp — Warnzustand vor [broken].
  lowEnergy,

  /// Energie komplett aufgebraucht. Braucht [Drone.repair], um
  /// weiterzuarbeiten — "Wartung, Ersatzteile" aus der Roadmap, hier
  /// bewusst minimal als einzelner Reset-Aufruf statt eigenem
  /// Ersatzteil-Inventar.
  broken,

  /// Kein abbaubares Ziel mehr in Reichweite (von der aufrufenden Schicht
  /// gesetzt, siehe [markDepleted]) — kein Fehlerzustand, sondern "hier
  /// gibt es gerade nichts mehr zu tun".
  depleted,
}

/// Eine einzelne automatische Arbeitsdrohne (Roadmap Phase 8, Progression
/// Stufe 3: "Einzelne lokale Drohnen") — V1 deckt genau einen Jobtyp ab:
/// automatisches Abbauen eines ihr zugewiesenen Nachbar-Tiles.
///
/// Bewusst ohne Bezug zu `vt_world`/Position/Pfadfindung, analog zu
/// `vt_npc.Npc` ("Bewusst ohne Pfadfindung/Bewegung — das lebt in der
/// Flame-/Spielschicht"): [tick] verwaltet nur Energie und
/// Abbau-Fortschritt und meldet per Rückgabewert, wann ein Abbauzyklus
/// abgeschlossen ist. Was dann tatsächlich abgebaut wird (welches Tile,
/// welche Ressource), entscheidet die aufrufende Spielschicht.
class Drone {
  /// Energie in `[0, 1]`. Sinkt während [DroneStatus.working]/
  /// [DroneStatus.lowEnergy], bleibt bei [DroneStatus.broken]/
  /// [DroneStatus.depleted] unverändert (nichts zu tun bzw. steht still).
  double energy;

  /// Fortschritt des aktuellen Abbauzyklus in `[0, 1)`. Erreicht er 1,
  /// ist ein Zyklus fertig — [tick] gibt dann `true` zurück und der
  /// Überschuss bleibt für den nächsten Zyklus erhalten, statt verloren
  /// zu gehen.
  double cycleProgress;

  DroneStatus status;

  /// Zähler abgeschlossener Abbauzyklen — nützlich für UI/Tests,
  /// unabhängig davon, ob die Spielschicht daraus tatsächlich Ressourcen
  /// gemacht hat.
  int completedCycles;

  Drone({
    this.energy = 1.0,
    this.cycleProgress = 0.0,
    this.status = DroneStatus.working,
    this.completedCycles = 0,
  }) : assert(energy >= 0 && energy <= 1, 'energy muss in [0,1] liegen'),
       assert(cycleProgress >= 0, 'cycleProgress darf nicht negativ sein');

  /// Energieverbrauch pro Sekunde aktiver Arbeit — bei Dauerbetrieb reicht
  /// eine volle Ladung für [fullEnergyDurationSeconds] Sekunden. Bewusst
  /// großzügig bemessen: eine Drohne soll in der Praxis fast immer an
  /// ausgehenden lokalen Ressourcen scheitern ([DroneStatus.depleted]),
  /// nicht an Energiemangel — Wartung/Reparatur ist ein Folgeschritt, kein
  /// Dauerthema in V1.
  static const double fullEnergyDurationSeconds = 180;
  static const double _energyDrainPerSecond = 1 / fullEnergyDurationSeconds;

  /// Dauer eines Abbauzyklus in Sekunden.
  static const double cycleDurationSeconds = 6;

  /// Ab diesem Energiewert wechselt der Status auf [DroneStatus.lowEnergy]
  /// als Frühwarnung, bevor die Drohne ganz stehen bleibt.
  static const double lowEnergyThreshold = 0.2;

  /// Ein Simulationsschritt. Gibt `true` zurück, wenn in diesem Aufruf ein
  /// Abbauzyklus abgeschlossen wurde — die aufrufende Spielschicht soll
  /// dann ein Ziel-Tile abbauen und den Ertrag verbuchen. Tut nichts, wenn
  /// die Drohne [DroneStatus.broken] oder [DroneStatus.depleted] ist.
  bool tick(double dtSeconds) {
    if (dtSeconds <= 0) return false;
    if (status == DroneStatus.broken || status == DroneStatus.depleted) return false;

    energy = (energy - _energyDrainPerSecond * dtSeconds).clamp(0.0, 1.0);
    if (energy <= 0) {
      status = DroneStatus.broken;
      cycleProgress = 0;
      return false;
    }
    status = energy < lowEnergyThreshold ? DroneStatus.lowEnergy : DroneStatus.working;

    cycleProgress += dtSeconds / cycleDurationSeconds;
    if (cycleProgress >= 1.0) {
      cycleProgress -= 1.0;
      completedCycles++;
      return true;
    }
    return false;
  }

  /// Lädt die Drohne wieder voll auf und setzt [DroneStatus.broken]
  /// zurück auf Arbeitsbetrieb ("Wartung" aus der Roadmap, hier als
  /// einzelner Vorgang statt eigenem Ersatzteil-System).
  void repair() {
    energy = 1.0;
    status = DroneStatus.working;
  }

  /// Markiert, dass kein Ziel mehr in Reichweite ist — von der
  /// Spielschicht aufgerufen, nicht von [tick] selbst, da nur sie weiß,
  /// ob noch ein abbaubares Nachbar-Tile existiert.
  void markDepleted() {
    status = DroneStatus.depleted;
  }
}
