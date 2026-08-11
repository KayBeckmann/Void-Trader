/// Art eines Himmelskörpers im System (Roadmap Phase 9: "Systemkarte").
/// Startet schmal — weitere Typen (Fraktions-Stationen, Speedway-Knoten,
/// Railgun-Fangstationen, …) folgen mit späteren Phase-9-Schritten.
enum CelestialBodyType {
  homePlanet,
  station,
  asteroidField,
}

/// Ein einzelner Himmelskörper im System — bewusst nur Anzeige-relevante
/// Daten (Name, Typ, Position). Die V1-Slice "Systemkarte" (Roadmap Phase
/// 9) ist reine Darstellung, noch keine Reise-/Flugmechanik — Bewegung
/// zwischen Körpern, Speedways und Andocken folgen später.
class CelestialBody {
  final String id;
  final String name;
  final CelestialBodyType type;

  /// Position im System in eigenen "Systemkarten"-Einheiten (nicht
  /// Welt-Tile-Koordinaten wie in vt_world) — der Ursprung (0,0) ist die
  /// Systemmitte.
  final double x;
  final double y;

  const CelestialBody({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
  });
}
