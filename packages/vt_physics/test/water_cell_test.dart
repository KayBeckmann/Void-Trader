import 'package:test/test.dart';
import 'package:vt_physics/vt_physics.dart';

void main() {
  group('WaterCell', () {
    test('surfaceHeight ist Gelände + Wasser', () {
      final cell = WaterCell(groundHeight: 2, waterLevel: 0.5);
      expect(cell.surfaceHeight, 2.5);
    });

    test('massive Zellen haben unendliche surfaceHeight', () {
      final cell = WaterCell(groundHeight: 0, waterLevel: 0, solid: true);
      expect(cell.surfaceHeight, double.infinity);
    });

    test('negativer waterLevel wird per Assertion verhindert', () {
      expect(() => WaterCell(waterLevel: -1), throwsA(isA<AssertionError>()));
    });
  });
}
