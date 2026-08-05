import 'package:test/test.dart';
import 'package:vt_physics/vt_physics.dart';

void main() {
  group('DayNightCycle', () {
    test('startet bei der übergebenen Tageszeit', () {
      final cycle = DayNightCycle(startTimeOfDay: 0.5);
      expect(cycle.timeOfDay, 0.5);
      expect(cycle.dayNumber, 0);
    });

    test('update() bewegt die Tageszeit proportional zur Taglänge', () {
      final cycle = DayNightCycle(dayLengthSeconds: 100, startTimeOfDay: 0);
      cycle.update(25);
      expect(cycle.timeOfDay, closeTo(0.25, 1e-9));
    });

    test('wickelt bei Erreichen von 1.0 um und erhöht dayNumber', () {
      final cycle = DayNightCycle(dayLengthSeconds: 100, startTimeOfDay: 0.9);
      cycle.update(20);
      expect(cycle.timeOfDay, closeTo(0.1, 1e-9));
      expect(cycle.dayNumber, 1);
    });

    test('mehrere volle Tage in einem update() erhöhen dayNumber entsprechend', () {
      final cycle = DayNightCycle(dayLengthSeconds: 100, startTimeOfDay: 0);
      cycle.update(250);
      expect(cycle.dayNumber, 2);
      expect(cycle.timeOfDay, closeTo(0.5, 1e-9));
    });

    test('isDay/isNight schalten an den Tagesgrenzen um', () {
      final cycle = DayNightCycle(startTimeOfDay: 0.5);
      expect(cycle.isDay, isTrue);
      expect(cycle.isNight, isFalse);

      final nightCycle = DayNightCycle(startTimeOfDay: 0.0);
      expect(nightCycle.isNight, isTrue);
      expect(nightCycle.isDay, isFalse);
    });

    test('lightLevel ist mittags am höchsten und mitternachts am niedrigsten', () {
      final noon = DayNightCycle(startTimeOfDay: 0.5);
      final midnight = DayNightCycle(startTimeOfDay: 0.0);
      expect(noon.lightLevel, closeTo(1.0, 1e-9));
      expect(midnight.lightLevel, closeTo(0.0, 1e-9));
      expect(noon.lightLevel, greaterThan(midnight.lightLevel));
    });

    test('ist deterministisch bei gleichen Parametern und Updates', () {
      final a = DayNightCycle(dayLengthSeconds: 60, startTimeOfDay: 0.1);
      final b = DayNightCycle(dayLengthSeconds: 60, startTimeOfDay: 0.1);
      for (final dt in [5.0, 12.0, 3.0, 40.0]) {
        a.update(dt);
        b.update(dt);
      }
      expect(a.timeOfDay, b.timeOfDay);
      expect(a.dayNumber, b.dayNumber);
    });

    test('wirft bei ungültigen Konstruktor-Parametern', () {
      expect(() => DayNightCycle(dayLengthSeconds: 0), throwsA(isA<AssertionError>()));
      expect(() => DayNightCycle(dayLengthSeconds: -1), throwsA(isA<AssertionError>()));
      expect(() => DayNightCycle(startTimeOfDay: 1.0), throwsA(isA<AssertionError>()));
      expect(() => DayNightCycle(startTimeOfDay: -0.1), throwsA(isA<AssertionError>()));
    });
  });
}
