import 'package:test/test.dart';
import 'package:vt_physics/vt_physics.dart';

void main() {
  group('WeatherSystem', () {
    test('startet mit dem übergebenen initialen Zustand', () {
      final system = WeatherSystem(initial: Weather.storm);
      expect(system.current, Weather.storm);
    });

    test('unterhalb des Check-Intervalls ändert sich nichts', () {
      final system = WeatherSystem(seed: 1, checkIntervalSeconds: 100);
      system.update(50);
      expect(system.current, Weather.clear);
    });

    test('ist deterministisch bei gleichem Seed und gleicher Update-Abfolge', () {
      final a = WeatherSystem(seed: 42, checkIntervalSeconds: 10);
      final b = WeatherSystem(seed: 42, checkIntervalSeconds: 10);

      final history = <Weather>[];
      for (var i = 0; i < 50; i++) {
        a.update(10);
        b.update(10);
        history.add(a.current);
        expect(a.current, b.current);
      }
      // Über 50 Übergänge sollte nicht ausschließlich "clear" vorkommen —
      // sonst würde die Zustandsmaschine gar nichts tun.
      expect(history.toSet().length, greaterThan(1));
    });

    test('unterschiedliche Seeds führen (meist) zu unterschiedlichen Verläufen', () {
      final a = WeatherSystem(seed: 1, checkIntervalSeconds: 10);
      final b = WeatherSystem(seed: 2, checkIntervalSeconds: 10);

      var differences = 0;
      for (var i = 0; i < 30; i++) {
        a.update(10);
        b.update(10);
        if (a.current != b.current) differences++;
      }
      expect(differences, greaterThan(0));
    });

    test('mehrere übersprungene Intervalle in einem update() werden alle verarbeitet', () {
      final withBigStep = WeatherSystem(seed: 7, checkIntervalSeconds: 10);
      final withSmallSteps = WeatherSystem(seed: 7, checkIntervalSeconds: 10);

      withBigStep.update(55); // 5 volle Intervalle auf einen Schlag
      for (var i = 0; i < 5; i++) {
        withSmallSteps.update(11); // 5x ein Intervall knapp überschritten
      }

      expect(withBigStep.current, withSmallSteps.current);
    });

    test('wirft bei ungültigem checkIntervalSeconds', () {
      expect(() => WeatherSystem(checkIntervalSeconds: 0), throwsA(isA<AssertionError>()));
      expect(() => WeatherSystem(checkIntervalSeconds: -5), throwsA(isA<AssertionError>()));
    });
  });
}
