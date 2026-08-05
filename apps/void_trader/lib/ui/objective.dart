import 'package:vt_content/vt_content.dart';

/// Ein einzelnes Einstiegs-Ziel mit sichtbarem Erfüllungsstatus (Roadmap
/// UI-07: "Ziele reagieren auf Spielfortschritt", "Zielerfüllung sichtbar
/// markieren"). Bewusst kein Quest-System — nur eine feste, kurze Liste als
/// Review-Führung für den ersten spielbaren Slice.
class ObjectiveStatus {
  final String description;
  final bool isComplete;

  const ObjectiveStatus({required this.description, required this.isComplete});
}

/// Baut die feste Zielkette aus der Roadmap. Reine Funktion auf einfachen
/// Fortschrittswerten statt einer direkten Abhängigkeit von
/// `VoidTraderGame` — bleibt so ohne echtes Spiel testbar.
List<ObjectiveStatus> buildObjectives({
  required int stoneCount,
  required Set<BuildingType> builtBuildingTypes,
  required int totalCrafted,
  required bool cargoEverLoaded,
}) {
  return [
    ObjectiveStatus(description: 'Sammle 3 Stein', isComplete: stoneCount >= 3),
    ObjectiveStatus(
      description: 'Baue eine Werkbank',
      isComplete: builtBuildingTypes.contains(BuildingType.workbench),
    ),
    ObjectiveStatus(description: 'Stelle 1 Bauteil her', isComplete: totalCrafted >= 1),
    ObjectiveStatus(
      description: 'Baue ein Landepad',
      isComplete: builtBuildingTypes.contains(BuildingType.landingPad),
    ),
    ObjectiveStatus(description: 'Lade Fracht ins Schiff', isComplete: cargoEverLoaded),
  ];
}
