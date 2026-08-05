import 'resource.dart';

/// Einfaches Mengen-Inventar für [Resource]s (Roadmap Phase 4).
///
/// Bewusst ohne Slots/Stacks/Gewicht — reine Zählmengen pro Rohstofftyp,
/// das reicht für "Sammeln → Verarbeiten → Ausbauen" in V1.
class Inventory {
  final Map<Resource, int> _counts = {};

  int count(Resource resource) => _counts[resource] ?? 0;

  bool has(Resource resource, int amount) {
    assert(amount >= 0, 'amount darf nicht negativ sein');
    return count(resource) >= amount;
  }

  void add(Resource resource, int amount) {
    assert(amount >= 0, 'amount darf nicht negativ sein');
    if (amount == 0) return;
    _counts[resource] = count(resource) + amount;
  }

  /// Entfernt [amount] von [resource]. Wirft, wenn nicht genug vorhanden
  /// ist — Aufrufer sollten vorher mit [has] prüfen, damit das nie
  /// überrascht.
  void remove(Resource resource, int amount) {
    assert(amount >= 0, 'amount darf nicht negativ sein');
    if (amount == 0) return;
    if (!has(resource, amount)) {
      throw StateError('Nicht genug $resource: ${count(resource)} < $amount');
    }
    _counts[resource] = count(resource) - amount;
  }

  /// Prüft, ob alle Mengen in [costs] vorhanden sind.
  bool hasAll(Map<Resource, int> costs) {
    return costs.entries.every((entry) => has(entry.key, entry.value));
  }

  /// Entfernt alle Mengen in [costs] auf einmal — alles oder nichts. Wirft,
  /// wenn irgendeine Menge nicht ausreicht; in dem Fall wird nichts
  /// abgezogen, damit kein Teilabzug bei fehlgeschlagenem Bau/Craft
  /// entsteht.
  void removeAll(Map<Resource, int> costs) {
    if (!hasAll(costs)) {
      throw StateError('Nicht genug Ressourcen für $costs');
    }
    costs.forEach(remove);
  }

  /// Wandelt Rohstoffe gemäß eines Rezepts um: zieht [input] ab und fügt
  /// [outputAmount] von [output] hinzu (Roadmap Phase 4: Werkbank/
  /// Schmelzer). Alles-oder-nichts wie [removeAll] — wirft ohne etwas zu
  /// verändern, wenn [input] nicht vollständig vorhanden ist.
  void craft(Map<Resource, int> input, Resource output, {int outputAmount = 1}) {
    assert(outputAmount > 0, 'outputAmount muss positiv sein');
    removeAll(input);
    add(output, outputAmount);
  }

  /// Unveränderliche Momentaufnahme aller aktuell gehaltenen Mengen.
  Map<Resource, int> get snapshot => Map.unmodifiable(_counts);
}
