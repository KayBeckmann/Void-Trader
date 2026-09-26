import 'inventory.dart';
import 'resource.dart';

/// Schiff als Lager-/Transporter (Roadmap Phase 7: Oberfläche↔Orbit-Brücke).
///
/// Bewusst minimal: ein eigenes [Inventory] als Frachtraum, getrennt vom
/// persönlichen Inventar des Spielers. Kapazitätsgrenzen und echte
/// Orbit-Mechanik kommen mit den Start-/Orbit-Infrastruktur-Tech-Stufen aus
/// der Roadmap später dazu. Der Frachtraum hat seit Phase 9 V10 ein
/// Kapazitätslimit ([cargoCapacity]). Treibstoff (Roadmap Phase 9, V9:
/// "Treibstoffverbrauch") lebt seit hier ebenfalls im Frachtraum — kein
/// separates Feld, damit derselbe [Inventory]-Mechanismus (`has`/`add`/
/// `remove`) für Reisekosten gilt wie für alles andere.
class Ship {
  final Inventory cargo = Inventory();

  /// Treibstoff-Startguthaben (Roadmap Phase 9, V9) — reicht für ein paar
  /// frühe Reisen im Heimatsystem (auch bis zum weiter entfernten
  /// Außenposten, siehe `defaultHomeSystem` in vt_system), damit der
  /// Spieler nicht sofort an einer leeren Tankanzeige hängen bleibt, bevor
  /// er überhaupt eine Handelsstation zum Auftanken kennengelernt hat.
  static const int startingFuel = 40;

  /// Maximale Menge an Frachteinheiten im Laderaum (Roadmap Phase 9, V10:
  /// "Frachtraum-Kapazitätslimit"). Gezählt wird nur echte Fracht
  /// ([cargoUsed]) — Treibstoff ist der Antrieb des Schiffs und Credits
  /// liegen beim Spieler, beides belegt keinen Laderaum. Ein Einkauf
  /// ([stationBuyBundle], 12 Einheiten Fracht) passt so mehrmals hinein,
  /// ein voll beladenes Schiff zwingt aber zum Verkaufen/Entladen.
  static const int cargoCapacity = 50;

  /// Belegter Laderaum: Summe aller Frachteinheiten ohne Treibstoff und
  /// Credits.
  int get cargoUsed => cargo.snapshot.entries
      .where((e) => e.key != Resource.fuel && e.key != Resource.credits)
      .fold(0, (sum, e) => sum + e.value);

  /// Noch freier Laderaum (nie negativ).
  int get freeCargoSpace => (cargoCapacity - cargoUsed).clamp(0, cargoCapacity);

  Ship() {
    cargo.add(Resource.fuel, startingFuel);
  }
}
