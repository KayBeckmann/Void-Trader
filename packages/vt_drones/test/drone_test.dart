import 'package:test/test.dart';
import 'package:vt_drones/vt_drones.dart';

void main() {
  group('Drone.tick', () {
    test('startet voll aufgeladen und arbeitend', () {
      final drone = Drone();
      expect(drone.energy, 1.0);
      expect(drone.status, DroneStatus.working);
      expect(drone.completedCycles, 0);
    });

    test('tut nichts bei dtSeconds <= 0', () {
      final drone = Drone();
      final yielded = drone.tick(0);
      expect(yielded, isFalse);
      expect(drone.energy, 1.0);
    });

    test('Energie sinkt während der Arbeit', () {
      final drone = Drone();
      drone.tick(10);
      expect(drone.energy, lessThan(1.0));
      expect(drone.energy, greaterThan(0.9));
    });

    test('meldet einen abgeschlossenen Zyklus nach cycleDurationSeconds', () {
      final drone = Drone();
      final yielded = drone.tick(Drone.cycleDurationSeconds);
      expect(yielded, isTrue);
      expect(drone.completedCycles, 1);
      expect(drone.cycleProgress, closeTo(0, 1e-9));
    });

    test('Überschuss-Fortschritt bleibt für den nächsten Zyklus erhalten', () {
      final drone = Drone();
      drone.tick(Drone.cycleDurationSeconds * 1.5);
      expect(drone.completedCycles, 1);
      expect(drone.cycleProgress, closeTo(0.5, 1e-9));
    });

    test('mehrere kleine Ticks summieren sich zu einem Zyklus', () {
      final drone = Drone();
      var yields = 0;
      // Eine Sekunde mehr als cycleDurationSeconds statt exakt genau so
      // viele Ticks — Aufsummieren von 1/6-Schritten in Gleitkomma landet
      // sonst durch Rundung knapp UNTER statt exakt bei 1.0.
      for (var i = 0; i < Drone.cycleDurationSeconds + 1; i++) {
        if (drone.tick(1.0)) yields++;
      }
      expect(yields, 1);
      expect(drone.completedCycles, 1);
    });

    test('wechselt zu lowEnergy unterhalb der Schwelle', () {
      final drone = Drone(energy: Drone.lowEnergyThreshold + 0.001);
      drone.tick(1.0);
      expect(drone.status, DroneStatus.lowEnergy);
    });

    test('wechselt zu broken, wenn die Energie aufgebraucht ist', () {
      final drone = Drone();
      drone.tick(Drone.fullEnergyDurationSeconds + 10);
      expect(drone.energy, 0);
      expect(drone.status, DroneStatus.broken);
    });

    test('broken-Drohnen arbeiten nicht weiter, bis repair() aufgerufen wird', () {
      final drone = Drone()..tick(Drone.fullEnergyDurationSeconds + 10);
      expect(drone.status, DroneStatus.broken);

      final yielded = drone.tick(Drone.cycleDurationSeconds);
      expect(yielded, isFalse);
      expect(drone.completedCycles, 0);
    });

    test('repair() lädt auf und setzt den Arbeitsstatus zurück', () {
      final drone = Drone()..tick(Drone.fullEnergyDurationSeconds + 10);
      drone.repair();

      expect(drone.energy, 1.0);
      expect(drone.status, DroneStatus.working);

      final yielded = drone.tick(Drone.cycleDurationSeconds);
      expect(yielded, isTrue);
    });

    test('depleted-Drohnen arbeiten nicht weiter', () {
      final drone = Drone()..markDepleted();
      final yielded = drone.tick(Drone.cycleDurationSeconds);

      expect(yielded, isFalse);
      expect(drone.status, DroneStatus.depleted);
      expect(drone.energy, 1.0); // unverändert, kein stiller Energieverbrauch
    });

    test('ist deterministisch: gleiche Tick-Folge liefert gleiches Ergebnis', () {
      final droneA = Drone();
      final droneB = Drone();
      final steps = [1.0, 2.5, 0.3, 4.0, 6.0, 0.1];

      for (final dt in steps) {
        expect(droneA.tick(dt), droneB.tick(dt));
      }
      expect(droneA.energy, droneB.energy);
      expect(droneA.cycleProgress, droneB.cycleProgress);
      expect(droneA.status, droneB.status);
      expect(droneA.completedCycles, droneB.completedCycles);
    });
  });

  group('Drone Konstruktion', () {
    test('wirft bei ungültiger Energie außerhalb [0,1]', () {
      expect(() => Drone(energy: 1.5), throwsA(isA<AssertionError>()));
      expect(() => Drone(energy: -0.1), throwsA(isA<AssertionError>()));
    });

    test('wirft bei negativem cycleProgress', () {
      expect(() => Drone(cycleProgress: -0.1), throwsA(isA<AssertionError>()));
    });
  });
}
