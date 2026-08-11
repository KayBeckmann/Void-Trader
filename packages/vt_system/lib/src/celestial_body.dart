/// Art eines Himmelskörpers im System (Roadmap Phase 9: "Systemkarte").
/// Startet schmal — weitere Typen (Fraktions-Stationen, Speedway-Knoten,
/// Railgun-Fangstationen, …) folgen mit späteren Phase-9-Schritten.
enum CelestialBodyType {
  homePlanet,
  station,
  asteroidField,
}

/// Ein einzelner Himmelskörper im System — bewusst nur Anzeige- und
/// wirtschaftlich relevante Basisdaten (Name, Typ, Position,
/// Preisniveau), noch keine Reise-/Flugmechanik jenseits von Standort-
/// Buchhaltung — echtes Andocken/Speedways folgen später.
class CelestialBody {
  final String id;
  final String name;
  final CelestialBodyType type;

  /// Position im System in eigenen "Systemkarten"-Einheiten (nicht
  /// Welt-Tile-Koordinaten wie in vt_world) — der Ursprung (0,0) ist die
  /// Systemmitte.
  final double x;
  final double y;

  /// Generischer Preisfaktor für Handel an diesem Körper (Roadmap Phase
  /// 9 V5: "Zweite Station mit eigenem Preisniveau") — 1.0 bedeutet
  /// Standardpreise. Bewusst als reiner Zahlenfaktor statt einer
  /// eigenen Ressourcen-Preistabelle modelliert: vt_system kennt keine
  /// [Resource]-Typen (die leben in vt_core/vt_content), sondern nur,
  /// "wie lohnend ist Handel hier" als generische Eigenschaft des Orts.
  /// Die eigentliche Umrechnung in Credits passiert in der Spielschicht
  /// (siehe VoidTraderGame.sellDockedShipCargo).
  final double priceMultiplier;

  const CelestialBody({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    this.priceMultiplier = 1.0,
  }) : assert(priceMultiplier > 0, 'priceMultiplier muss positiv sein');
}
