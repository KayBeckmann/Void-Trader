import 'tile.dart';

/// Reine, headless testbare Klassifikationsfunktion für die
/// Oberflächengenerierung (Roadmap Phase 2: Biome, Höhen-/Feuchtigkeits-/
/// Temperaturkarten).
///
/// Alle Eingaben werden als Werte in `[0, 1)` erwartet (siehe `NoiseField`
/// in noise.dart). Absichtlich simpel gehalten (Schwellenwerte statt
/// komplexer Übergangsfunktionen) — "Generation V1" nach Roadmap.
TileType surfaceTileForBiome({
  required double height,
  required double moisture,
  required double temperature,
}) {
  // Niedrig gelegene Bereiche: Wasserquellen/kleine Seen, mit schmalem
  // Uferstreifen davor.
  if (height < 0.30) return TileType.water;
  if (height < 0.35) return TileType.dirt;

  // Hoch gelegene Bereiche: felsiges Hochland.
  if (height > 0.85) return TileType.stone;

  // Feuchtes Klima: Wald.
  if (moisture > 0.62) return TileType.forest;

  // Trockenes, warmes Klima: karger Boden statt Wiese.
  if (moisture < 0.25 && temperature > 0.55) return TileType.dirt;

  // Standardfall: Wiese.
  return TileType.grass;
}
