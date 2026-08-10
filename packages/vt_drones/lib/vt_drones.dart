/// Drohnenlogik für Void Trader (Roadmap Phase 8: "Drohnenlogik und
/// Automatisierung").
///
/// Reine Dart-Simulation ohne Flutter-/Flame-/Weltbezug (siehe
/// docs/ARCHITECTURE.md: "Dart-Core zuerst") — analog zu `vt_npc`: eine
/// [Drone] kennt nur ihren inneren Zustand (Energie, Abbau-Fortschritt,
/// Status), keine Position oder Pfadfindung. Das lebt in der Spielschicht
/// (`apps/void_trader`).
library;

export 'src/drone.dart';
