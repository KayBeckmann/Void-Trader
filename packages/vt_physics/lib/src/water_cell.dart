/// Eine einzelne Zelle der diskreten Wassersimulation.
///
/// Statt einzelner Partikel wird pro Zelle nur eine Wasserhöhe gespeichert
/// (siehe Roadmap "Offene Entscheidungen": diskrete Wasserhöhe pro Tile
/// statt Partikel). [groundHeight] ist die feste Geländehöhe, [waterLevel]
/// die veränderliche Wassermenge obendrauf.
class WaterCell {
  /// Feste Geländehöhe dieser Zelle.
  double groundHeight;

  /// Aktuelle Wassermenge über dem Gelände. Nie negativ.
  double waterLevel;

  /// Massive Zellen (z.B. Fels) nehmen kein Wasser auf und blockieren Fluss.
  final bool solid;

  WaterCell({this.groundHeight = 0, this.waterLevel = 0, this.solid = false})
    : assert(waterLevel >= 0, 'waterLevel darf nicht negativ sein');

  /// Gesamthöhe der Wasseroberfläche (Gelände + Wasser). Für massive Zellen
  /// wird `infinity` verwendet, damit sie nie als "niedriger" gelten und
  /// so kein Wasser anziehen.
  double get surfaceHeight =>
      solid ? double.infinity : groundHeight + waterLevel;

  @override
  String toString() =>
      'WaterCell(ground: $groundHeight, water: $waterLevel, solid: $solid)';
}
