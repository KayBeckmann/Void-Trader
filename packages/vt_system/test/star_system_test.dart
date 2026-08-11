import 'package:test/test.dart';
import 'package:vt_system/vt_system.dart';

void main() {
  group('StarSystem', () {
    test('homePlanet liefert den Körper vom Typ homePlanet', () {
      const system = StarSystem(
        name: 'Test-System',
        bodies: [
          CelestialBody(
            id: 'station',
            name: 'Station',
            type: CelestialBodyType.station,
            x: 10,
            y: 10,
          ),
          CelestialBody(
            id: 'home',
            name: 'Heimatwelt',
            type: CelestialBodyType.homePlanet,
            x: 0,
            y: 0,
          ),
        ],
      );

      expect(system.homePlanet.id, 'home');
    });

    test('homePlanet wirft, wenn kein Körper vom Typ homePlanet existiert', () {
      const system = StarSystem(
        name: 'Test-System',
        bodies: [
          CelestialBody(
            id: 'station',
            name: 'Station',
            type: CelestialBodyType.station,
            x: 10,
            y: 10,
          ),
        ],
      );

      expect(() => system.homePlanet, throwsStateError);
    });
  });

  group('CelestialBody.priceMultiplier (Roadmap Phase 9 V5)', () {
    test('ist standardmäßig 1.0', () {
      const body = CelestialBody(
        id: 'station',
        name: 'Station',
        type: CelestialBodyType.station,
        x: 0,
        y: 0,
      );

      expect(body.priceMultiplier, 1.0);
    });

    test('wirft bei nicht-positivem Wert', () {
      expect(
        () => CelestialBody(
          id: 'station',
          name: 'Station',
          type: CelestialBodyType.station,
          x: 0,
          y: 0,
          priceMultiplier: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CelestialBody(
          id: 'station',
          name: 'Station',
          type: CelestialBodyType.station,
          x: 0,
          y: 0,
          priceMultiplier: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('defaultHomeSystem', () {
    test('enthält genau einen Heimatplaneten im Systemursprung', () {
      final home = defaultHomeSystem.homePlanet;

      expect(home.type, CelestialBodyType.homePlanet);
      expect(home.x, 0);
      expect(home.y, 0);
    });

    test('enthält mindestens zwei weitere Himmelskörper', () {
      final others = defaultHomeSystem.bodies.where(
        (body) => body.type != CelestialBodyType.homePlanet,
      );

      expect(others.length, greaterThanOrEqualTo(2));
    });

    test('jeder Körper hat eine eindeutige id', () {
      final ids = defaultHomeSystem.bodies.map((body) => body.id).toSet();

      expect(ids.length, defaultHomeSystem.bodies.length);
    });

    test('jeder Körper hat einen nicht-leeren Namen', () {
      for (final body in defaultHomeSystem.bodies) {
        expect(body.name, isNotEmpty, reason: '${body.id} hat keinen Namen');
      }
    });

    test('enthält mindestens zwei Stationen mit unterschiedlichem Preisniveau', () {
      final stations = defaultHomeSystem.bodies.where(
        (body) => body.type == CelestialBodyType.station,
      );

      expect(stations.length, greaterThanOrEqualTo(2));
      final multipliers = stations.map((s) => s.priceMultiplier).toSet();
      expect(
        multipliers.length,
        greaterThan(1),
        reason: 'mindestens zwei Stationen sollten unterschiedlich viel zahlen',
      );
    });
  });
}
