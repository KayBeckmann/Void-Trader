import 'package:test/test.dart';
import 'package:vt_physics/vt_physics.dart';

void main() {
  group('FluidGrid', () {
    test('flaches, wasserloses Grid bleibt nach step() unverändert', () {
      final grid = FluidGrid(3, 3);
      grid.step();
      expect(grid.totalWater(), 0);
    });

    test('Wasser fließt von höherer zu niedrigerer Zelle', () {
      final grid = FluidGrid(2, 1);
      grid.setGroundHeight(0, 0, 2);
      grid.setGroundHeight(1, 0, 0);
      grid.addWater(0, 0, 1);

      grid.step();

      expect(grid.cellAt(0, 0).waterLevel, lessThan(1));
      expect(grid.cellAt(1, 0).waterLevel, greaterThan(0));
    });

    test('Gesamtwassermenge bleibt über viele Schritte erhalten', () {
      final grid = FluidGrid(5, 5);
      grid.setGroundHeight(2, 2, 3);
      grid.addWater(2, 2, 10);

      final before = grid.totalWater();
      for (var i = 0; i < 50; i++) {
        grid.step();
      }
      final after = grid.totalWater();

      expect(after, closeTo(before, 1e-9));
    });

    test('massive Zellen blockieren Fluss und bleiben trocken', () {
      final grid = FluidGrid(3, 1);
      grid.setGroundHeight(0, 0, 5);
      grid.setSolid(1, 0, solid: true);
      grid.addWater(0, 0, 1);

      for (var i = 0; i < 20; i++) {
        grid.step();
      }

      expect(grid.cellAt(1, 0).waterLevel, 0);
      expect(grid.cellAt(2, 0).waterLevel, 0);
    });

    test('zwei verbundene Zellen gleichen sich über mehrere Schritte an', () {
      final grid = FluidGrid(2, 1);
      grid.addWater(0, 0, 4);

      for (var i = 0; i < 100; i++) {
        grid.step();
      }

      expect(
        grid.cellAt(0, 0).waterLevel,
        closeTo(grid.cellAt(1, 0).waterLevel, 1e-6),
      );
    });

    test(
      'Höhle (niedrige Zelle umgeben von Fels) kann geflutet werden',
      () {
        final grid = FluidGrid(3, 3);
        for (var y = 0; y < 3; y++) {
          for (var x = 0; x < 3; x++) {
            grid.setGroundHeight(x, y, 5);
          }
        }
        // Mittlere Zelle ist eine Höhle (niedriger als Umgebung).
        grid.setGroundHeight(1, 1, 0);
        grid.addWater(1, 0, 2);

        for (var i = 0; i < 50; i++) {
          grid.step();
        }

        expect(grid.cellAt(1, 1).waterLevel, greaterThan(0));
      },
    );
  });
}
