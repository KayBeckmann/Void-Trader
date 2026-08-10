import 'package:vt_core/vt_core.dart';

/// Baubare Objekte (Roadmap Phase 4: Baublöcke). Startet schmal mit zwei
/// Bausteinen, die zusammen "Sammeln → Verarbeiten → Ausbauen" zeigen —
/// weitere Baublöcke (Zäune, Lagerkisten, Pumpe, …) folgen später.
enum BuildingType {
  wall,
  workbench,
  market,
  landingPad,
  storage,

  /// Erste automatische Arbeitsdrohne (Roadmap Phase 8: "Drohnenlogik und
  /// Automatisierung"). Anders als die übrigen Gebäude hängt an einer
  /// platzierten Minendrohne ein eigenes Innenleben (Energie,
  /// Abbau-Fortschritt aus dem `vt_drones`-Paket) — siehe
  /// VoidTraderGame.drones in `apps/void_trader`.
  miningDrone,

  /// Pumpt automatisch Wasser aus einem angrenzenden gefluteten Tile ab
  /// (Roadmap MVP-Definition Punkt 5: "Spieler kann mit Graben/Pumpe/
  /// Abdichten reagieren"). Anders als die Minendrohne ohne eigenes
  /// Innenleben — nur eine Weltposition, siehe VoidTraderGame.pumps in
  /// `apps/void_trader`.
  pump,
}

/// Balancing-Daten für einen [BuildingType]: Name + Baukosten in
/// Rohstoffen.
class BuildingDefinition {
  final BuildingType type;
  final String name;
  final Map<Resource, int> buildCost;

  const BuildingDefinition({
    required this.type,
    required this.name,
    required this.buildCost,
  });
}

/// Balancing-Tabelle aller Gebäude-Definitionen.
const Map<BuildingType, BuildingDefinition> buildingDefinitions = {
  BuildingType.wall: BuildingDefinition(
    type: BuildingType.wall,
    name: 'Mauer',
    buildCost: {Resource.stone: 3},
  ),
  BuildingType.workbench: BuildingDefinition(
    type: BuildingType.workbench,
    name: 'Werkbank',
    buildCost: {Resource.stone: 2, Resource.ore: 1},
  ),
  BuildingType.market: BuildingDefinition(
    type: BuildingType.market,
    name: 'Marktkiosk',
    buildCost: {Resource.stone: 5, Resource.ore: 2},
  ),
  BuildingType.landingPad: BuildingDefinition(
    type: BuildingType.landingPad,
    name: 'Landepad',
    buildCost: {Resource.stone: 8, Resource.ore: 4, Resource.component: 2},
  ),
  BuildingType.storage: BuildingDefinition(
    type: BuildingType.storage,
    name: 'Lager',
    buildCost: {Resource.stone: 4},
  ),
  BuildingType.miningDrone: BuildingDefinition(
    type: BuildingType.miningDrone,
    name: 'Minendrohne',
    buildCost: {Resource.stone: 4, Resource.ore: 2, Resource.component: 3},
  ),
  BuildingType.pump: BuildingDefinition(
    type: BuildingType.pump,
    name: 'Pumpe',
    buildCost: {Resource.stone: 3, Resource.component: 2},
  ),
};

/// Bequemlichkeitszugriff auf [buildingDefinitions].
BuildingDefinition buildingDefinitionFor(BuildingType type) {
  final definition = buildingDefinitions[type];
  if (definition == null) {
    throw StateError('Keine BuildingDefinition für $type hinterlegt');
  }
  return definition;
}

/// Bewegungs-Eigenschaft je Gebäudetyp (Roadmap MOV-01: "Gebäude ... sind
/// Hindernisse"). Jedes platzierte Gebäude blockiert die Bewegung — man
/// steht neben seiner Werkbank, nicht in ihr. Als Erweiterung statt
/// festem `true` in [World.placeBuildingAt] modelliert, damit ein
/// zukünftiger begehbarer Gebäudetyp (z.B. ein Bodenpanel) die Regel
/// gezielt überschreiben kann, ohne die Aufrufer anzufassen.
extension BuildingMovement on BuildingType {
  bool get blocksMovement => true;
}
