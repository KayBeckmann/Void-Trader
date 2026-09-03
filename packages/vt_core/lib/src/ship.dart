import 'inventory.dart';
import 'resource.dart';

/// Schiff als Lager-/Transporter (Roadmap Phase 7: Oberfläche↔Orbit-Brücke).
///
/// Bewusst minimal: ein eigenes [Inventory] als Frachtraum, getrennt vom
/// persönlichen Inventar des Spielers. Kapazitätsgrenzen und echte
/// Orbit-Mechanik kommen mit den Start-/Orbit-Infrastruktur-Tech-Stufen aus
/// der Roadmap später dazu. Treibstoff (Roadmap Phase 9, V9:
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

  Ship() {
    cargo.add(Resource.fuel, startingFuel);
  }
}
