import 'tile.dart';
import 'world.dart';
import 'z_level.dart';

/// Ergebnis einer [validateStartZone]-Prüfung (Roadmap MOV-04:
/// "Startzonen-Fairness"). Rein datenhaltend, damit Aufrufer (Weltgenerator,
/// Tests, spätere Seed-Auswahl) selbst entscheiden können, was mit einer
/// unfairen Startzone passiert.
class StartZoneReport {
  /// Anzahl der über begehbare Tiles vom Startpunkt aus erreichbaren Tiles
  /// (begrenzt durch das Suchbudget, siehe [validateStartZone]).
  final int reachableTileCount;

  /// Ob mindestens eine abbaubare Ressource (Stein/Erz/Felswand) direkt an
  /// ein erreichbares Tile angrenzt — abbaubare Tiles blockieren selbst die
  /// Bewegung (MOV-01) und liegen deshalb nie *im* erreichbaren Bereich,
  /// sondern höchstens direkt daneben.
  final bool hasReachableMinableResource;

  /// Gesamturteil: genug zusammenhängende Fläche UND eine erreichbare
  /// Ressource. Kein Insel-/Wasser-Gefängnis.
  final bool isFair;

  const StartZoneReport({
    required this.reachableTileCount,
    required this.hasReachableMinableResource,
    required this.isFair,
  });

  @override
  String toString() =>
      'StartZoneReport(reachable: $reachableTileCount, '
      'hasResource: $hasReachableMinableResource, fair: $isFair)';
}

/// Prüft, ob die Startzone rund um [startX]/[startY] fair ist (Roadmap
/// MOV-04): eine ausreichend große zusammenhängende begehbare Fläche und
/// mindestens eine abbaubare Ressource in Reichweite. Deterministisch und
/// ohne Rendering testbar — reine Flood-Fill-/Nachbarschaftsprüfung auf
/// [World].
StartZoneReport validateStartZone(
  World world, {
  int startX = 0,
  int startY = 0,
  int z = ZLevel.surface,
  int minReachableTiles = 40,
  int searchBudget = 600,
}) {
  final reachable = world.reachableTilesFrom(startX, startY, z, maxTiles: searchBudget);

  var hasResource = false;
  for (final tile in reachable) {
    for (final neighbor in _fourNeighbors(tile)) {
      if (world.tileAt(neighbor.x, neighbor.y, z).type.isMinable) {
        hasResource = true;
        break;
      }
    }
    if (hasResource) break;
  }

  return StartZoneReport(
    reachableTileCount: reachable.length,
    hasReachableMinableResource: hasResource,
    isFair: reachable.length >= minReachableTiles && hasResource,
  );
}

Iterable<({int x, int y})> _fourNeighbors(({int x, int y}) tile) sync* {
  yield (x: tile.x + 1, y: tile.y);
  yield (x: tile.x - 1, y: tile.y);
  yield (x: tile.x, y: tile.y + 1);
  yield (x: tile.x, y: tile.y - 1);
}
