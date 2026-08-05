import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('surfaceTileForBiome', () {
    test('sehr niedrige Höhe -> Wasser (See)', () {
      final type = surfaceTileForBiome(height: 0.1, moisture: 0.5, temperature: 0.5);
      expect(type, TileType.water);
    });

    test('knapp über Wasserlinie -> Ufer (Erde)', () {
      final type = surfaceTileForBiome(height: 0.32, moisture: 0.5, temperature: 0.5);
      expect(type, TileType.dirt);
    });

    test('sehr hohe Höhe -> Felsland', () {
      final type = surfaceTileForBiome(height: 0.9, moisture: 0.5, temperature: 0.5);
      expect(type, TileType.stone);
    });

    test('hohe Feuchtigkeit auf normaler Höhe -> Wald', () {
      final type = surfaceTileForBiome(height: 0.5, moisture: 0.8, temperature: 0.5);
      expect(type, TileType.forest);
    });

    test('trocken und warm -> karger Boden', () {
      final type = surfaceTileForBiome(height: 0.5, moisture: 0.1, temperature: 0.8);
      expect(type, TileType.dirt);
    });

    test('trocken aber kalt -> normale Wiese (kein Wüsteneffekt)', () {
      final type = surfaceTileForBiome(height: 0.5, moisture: 0.1, temperature: 0.2);
      expect(type, TileType.grass);
    });

    test('mittlere Werte überall -> Wiese als Standardfall', () {
      final type = surfaceTileForBiome(height: 0.5, moisture: 0.45, temperature: 0.5);
      expect(type, TileType.grass);
    });

    test('Höhe hat Vorrang vor Feuchtigkeit (Wasser trotz hoher Feuchtigkeit)', () {
      final type = surfaceTileForBiome(height: 0.1, moisture: 0.9, temperature: 0.5);
      expect(type, TileType.water);
    });
  });
}
