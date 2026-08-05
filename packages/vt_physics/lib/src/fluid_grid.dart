import 'water_cell.dart';

/// Rechteckiges Gitter aus [WaterCell]s mit einer deterministischen
/// `step()`-Funktion (Roadmap Phase 3: Fluid/Wasser).
///
/// Fließrichtung ergibt sich aus dem Höhenunterschied (Gelände + Wasser)
/// zwischen 4-fach benachbarten Zellen. Wasser fließt anteilig zu allen
/// niedrigeren Nachbarn, begrenzt durch [flowRate] pro Schritt, damit die
/// Simulation stabil bleibt statt zu oszillieren. Die Gesamtwassermenge
/// bleibt dabei erhalten (abzüglich massiver Zellen, die nie Wasser
/// aufnehmen).
class FluidGrid {
  final int width;
  final int height;
  final List<List<WaterCell>> _cells;

  FluidGrid(this.width, this.height)
    : _cells = List.generate(
        height,
        (_) => List.generate(width, (_) => WaterCell()),
      );

  WaterCell cellAt(int x, int y) => _cells[y][x];

  bool _inBounds(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  void setGroundHeight(int x, int y, double heightValue) {
    _cells[y][x].groundHeight = heightValue;
  }

  void setSolid(int x, int y, {required bool solid}) {
    final old = _cells[y][x];
    _cells[y][x] = WaterCell(
      groundHeight: old.groundHeight,
      waterLevel: solid ? 0 : old.waterLevel,
      solid: solid,
    );
  }

  void addWater(int x, int y, double amount) {
    final cell = _cells[y][x];
    if (cell.solid || amount <= 0) return;
    cell.waterLevel += amount;
  }

  double totalWater() {
    var sum = 0.0;
    for (final row in _cells) {
      for (final cell in row) {
        if (!cell.solid) sum += cell.waterLevel;
      }
    }
    return sum;
  }

  List<({int x, int y})> _neighbors(int x, int y) {
    const offsets = [(1, 0), (-1, 0), (0, 1), (0, -1)];
    return [
      for (final (dx, dy) in offsets)
        if (_inBounds(x + dx, y + dy)) (x: x + dx, y: y + dy),
    ];
  }

  /// Führt einen deterministischen Simulationsschritt aus.
  ///
  /// [flowRate] bestimmt den Anteil des überschüssigen Wassers einer Zelle,
  /// der pro Schritt maximal an niedrigere Nachbarn abgegeben wird (0..1).
  void step({double flowRate = 0.5}) {
    assert(flowRate > 0 && flowRate <= 1, 'flowRate muss in (0, 1] liegen');

    final outflow = List.generate(height, (_) => List.filled(width, 0.0));
    final inflow = List.generate(height, (_) => List.filled(width, 0.0));

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final cell = _cells[y][x];
        if (cell.solid || cell.waterLevel <= 0) continue;

        final lowerNeighbors = _neighbors(x, y)
            .where((n) => cellAt(n.x, n.y).surfaceHeight < cell.surfaceHeight)
            .toList();
        if (lowerNeighbors.isEmpty) continue;

        var totalDiff = 0.0;
        for (final n in lowerNeighbors) {
          totalDiff += cell.surfaceHeight - cellAt(n.x, n.y).surfaceHeight;
        }

        final movable = cell.waterLevel * flowRate;
        for (final n in lowerNeighbors) {
          final diff = cell.surfaceHeight - cellAt(n.x, n.y).surfaceHeight;
          final amount = movable * (diff / totalDiff);
          outflow[y][x] += amount;
          inflow[n.y][n.x] += amount;
        }
      }
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final cell = _cells[y][x];
        if (cell.solid) continue;
        cell.waterLevel += inflow[y][x] - outflow[y][x];
      }
    }
  }
}
