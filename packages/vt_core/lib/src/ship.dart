import 'inventory.dart';

/// Schiff als Lager-/Transporter (Roadmap Phase 7: Oberfläche↔Orbit-Brücke).
///
/// Bewusst minimal: ein eigenes [Inventory] als Frachtraum, getrennt vom
/// persönlichen Inventar des Spielers. Kapazitätsgrenzen, Treibstoff und
/// echte Orbit-Mechanik kommen mit den Start-/Orbit-Infrastruktur-
/// Tech-Stufen aus der Roadmap später dazu — hier geht es zunächst nur
/// darum, dass Fracht überhaupt einen zweiten Ort hat.
class Ship {
  final Inventory cargo = Inventory();
}
