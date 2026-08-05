import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('ValueNoise2D', () {
    test('ist deterministisch für gleichen Seed und gleiche Koordinate', () {
      const noise = ValueNoise2D(42);
      expect(noise.sample(3.5, -2.25), noise.sample(3.5, -2.25));
    });

    test('unterschiedliche Seeds liefern meist unterschiedliche Werte', () {
      const a = ValueNoise2D(1);
      const b = ValueNoise2D(2);

      var differences = 0;
      for (var x = 0; x < 20; x++) {
        for (var y = 0; y < 20; y++) {
          if (a.sample(x + 0.3, y + 0.7) != b.sample(x + 0.3, y + 0.7)) {
            differences++;
          }
        }
      }
      expect(differences, greaterThan(0));
    });

    test('Werte liegen im Bereich [0, 1]', () {
      const noise = ValueNoise2D(9);
      for (var x = 0; x < 50; x++) {
        for (var y = 0; y < 50; y++) {
          final value = noise.sample(x * 0.37, y * 0.53);
          expect(value, inInclusiveRange(0.0, 1.0));
        }
      }
    });

    test('ist stetig: eng benachbarte Punkte liefern ähnliche Werte', () {
      const noise = ValueNoise2D(5);
      final base = noise.sample(10.123, 4.456);
      final near = noise.sample(10.124, 4.456);
      expect((base - near).abs(), lessThan(0.01));
    });
  });

  group('NoiseField', () {
    test('ist deterministisch', () {
      final field = NoiseField(seed: 3, scale: 16);
      expect(field.valueAt(10, 20), field.valueAt(10, 20));
    });

    test('unterschiedlicher zOffset liefert meist andere Werte', () {
      final field = NoiseField(seed: 3, scale: 8);
      var differences = 0;
      for (var x = 0; x < 20; x++) {
        for (var y = 0; y < 20; y++) {
          if (field.valueAt(x, y) != field.valueAt(x, y, zOffset: 137)) {
            differences++;
          }
        }
      }
      expect(differences, greaterThan(0));
    });

    test('wirft bei scale <= 0', () {
      expect(() => NoiseField(seed: 1, scale: 0), throwsA(isA<AssertionError>()));
      expect(() => NoiseField(seed: 1, scale: -5), throwsA(isA<AssertionError>()));
    });
  });
}
