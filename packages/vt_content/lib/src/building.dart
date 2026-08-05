import 'package:vt_core/vt_core.dart';

/// Baubare Objekte (Roadmap Phase 4: Baublöcke). Startet schmal mit zwei
/// Bausteinen, die zusammen "Sammeln → Verarbeiten → Ausbauen" zeigen —
/// weitere Baublöcke (Zäune, Lagerkisten, Pumpe, …) folgen später.
enum BuildingType { wall, workbench }

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
};

/// Bequemlichkeitszugriff auf [buildingDefinitions].
BuildingDefinition buildingDefinitionFor(BuildingType type) {
  final definition = buildingDefinitions[type];
  if (definition == null) {
    throw StateError('Keine BuildingDefinition für $type hinterlegt');
  }
  return definition;
}
