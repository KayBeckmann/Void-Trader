/// Sternensystem-Datenmodell für Void Trader (Roadmap Phase 9:
/// "Erweiterung nach oben: System, Speedways, Galaxy").
///
/// Reine Dart-Simulation ohne Flutter-/Flame-Bezug (siehe
/// docs/ARCHITECTURE.md: "Dart-Core zuerst") — analog zu `vt_drones`/
/// `vt_npc`: kennt nur Namen/Typ/Position der Himmelskörper, kein
/// Rendering und keine Reise-/Flugmechanik. Das lebt in der Spielschicht
/// (`apps/void_trader`).
library;

export 'src/celestial_body.dart';
export 'src/star_system.dart';
