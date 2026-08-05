/// Vertikale Ebenen der Weltstruktur (siehe Roadmap Phase 2: World > Region >
/// Chunk(x, y) > Layers(z) > Tiles).
///
/// Ebenen werden von Anfang an modelliert, auch wenn Phase 1 nur die
/// Oberfläche (`surface`) spielerisch nutzt.
abstract final class ZLevel {
  static const int mountains = 2;
  static const int hills = 1;
  static const int surface = 0;
  static const int cellar = -1;
  static const int caves = -2;
  static const int deepCaves = -3;

  /// Alle Ebenen, oben nach unten sortiert.
  static const List<int> all = [
    mountains,
    hills,
    surface,
    cellar,
    caves,
    deepCaves,
  ];
}
