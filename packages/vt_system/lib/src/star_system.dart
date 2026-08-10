import 'celestial_body.dart';

/// Ein Sternensystem: Name + die darin enthaltenen Himmelskörper.
class StarSystem {
  final String name;
  final List<CelestialBody> bodies;

  const StarSystem({required this.name, required this.bodies});

  /// Der Heimatplanet dieses Systems — genau einer pro System (Roadmap
  /// Phase 9 V1: nur ein Startpunkt, keine Mehrfachbesiedlung). Wirft,
  /// statt still `null` zu liefern, wenn ein System diese Invariante
  /// verletzt.
  CelestialBody get homePlanet =>
      bodies.firstWhere((body) => body.type == CelestialBodyType.homePlanet);
}

/// Standard-Heimatsystem, in dem der Spieler startet (Roadmap Phase 9,
/// V1-Slice "Systemkarte") — bewusst statisch/deterministisch statt
/// prozedural generiert, analog zum bewusst schmalen Umfang der ersten
/// Minendrohne in Phase 8. Prozedurale Systemgenerierung, mehrere
/// Systeme und eine Galaxykarte sind spätere Phase-9-Schritte.
const defaultHomeSystem = StarSystem(
  name: 'Kepler-9-System',
  bodies: [
    CelestialBody(
      id: 'home-planet',
      name: 'Void Trader Heimatwelt',
      type: CelestialBodyType.homePlanet,
      x: 0,
      y: 0,
    ),
    CelestialBody(
      id: 'trading-station',
      name: 'Handelsstation Kepler-9b',
      type: CelestialBodyType.station,
      x: 120,
      y: -60,
    ),
    CelestialBody(
      id: 'asteroid-field',
      name: 'Asteroidengürtel Kepler-9c',
      type: CelestialBodyType.asteroidField,
      x: -100,
      y: 80,
    ),
  ],
);
