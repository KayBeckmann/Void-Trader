import 'dart:math';

import 'tile.dart';
import 'world.dart';

/// Sichtzustand eines einzelnen Tiles (Roadmap FOW-01).
enum VisibilityState {
  /// Noch nie gesehen — stark dunkel/verdeckt im Rendering.
  unseen,

  /// Bereits entdeckt, aber aktuell nicht im Sichtfeld — abgedunkelt,
  /// bleibt aber als bekannt sichtbar.
  seenButNotVisible,

  /// Aktuell im Sichtfeld — normal hell.
  visible,
}

/// Hält fest, welche Tiles der Spieler jemals gesehen hat und welche
/// gerade aktuell sichtbar sind (Roadmap FOW-01: "Entdeckte Tiles bleiben
/// im Savegame"). Bewusst reines Dart ohne Rendering-Bezug — der
/// Fog-Renderer (FOW-04) liest nur [stateAt].
class ExplorationTracker {
  final Set<({int x, int y})> _discovered = {};
  Set<({int x, int y})> _currentlyVisible = const {};

  /// Ersetzt die aktuell sichtbare Menge (z.B. Ergebnis von
  /// [computeFieldOfView]) und merkt sich alle neuen Tiles dauerhaft als
  /// entdeckt.
  void update(Set<({int x, int y})> visibleNow) {
    _currentlyVisible = visibleNow;
    _discovered.addAll(visibleNow);
  }

  VisibilityState stateAt(int x, int y) {
    final tile = (x: x, y: y);
    if (_currentlyVisible.contains(tile)) return VisibilityState.visible;
    if (_discovered.contains(tile)) return VisibilityState.seenButNotVisible;
    return VisibilityState.unseen;
  }

  int get discoveredCount => _discovered.length;
  Set<({int x, int y})> get currentlyVisible => _currentlyVisible;
}

/// Berechnet die aktuell sichtbaren Welt-Tile-Koordinaten von [originX]/
/// [originY] aus (Roadmap FOW-02: "Sichtkegel mit Blickrichtung", FOW-03:
/// "Sichtblocker"):
///
/// - ein kleiner Nahbereich ([nearRadius]) ist immer sichtbar, unabhängig
///   von der Blickrichtung — man sieht auch neben/hinter sich ein Stück;
/// - darüber hinaus nur ein Kegel ([fieldOfViewDegrees] breit) in
///   Blickrichtung ([facingX]/[facingY], muss kein Einheitsvektor sein);
/// - Sichtblocker (Wald/Fels/Gebäude, siehe [TileMovement.blocksSight])
///   verdecken dahinterliegende Tiles, aber nicht sich selbst — man sieht
///   die Felswand, nur nicht, was dahinter liegt.
///
/// Bewusst mit Radius-Budget statt echtem Raycasting über die ganze Karte
/// — "FOV-Berechnung muss budgetiert und chunk-fähig sein" (Roadmap).
Set<({int x, int y})> computeFieldOfView({
  required World world,
  required int originX,
  required int originY,
  required int z,
  required double facingX,
  required double facingY,
  int viewRadius = 8,
  double fieldOfViewDegrees = 130,
  int nearRadius = 2,
}) {
  final visible = <({int x, int y})>{(x: originX, y: originY)};

  final facingLength = sqrt(facingX * facingX + facingY * facingY);
  final normFacingX = facingLength > 0 ? facingX / facingLength : 0.0;
  final normFacingY = facingLength > 0 ? facingY / facingLength : 1.0;
  final halfAngleRad = (fieldOfViewDegrees / 2) * pi / 180;

  for (var dx = -viewRadius; dx <= viewRadius; dx++) {
    for (var dy = -viewRadius; dy <= viewRadius; dy++) {
      if (dx == 0 && dy == 0) continue;
      final distance = sqrt((dx * dx + dy * dy).toDouble());
      if (distance > viewRadius) continue;

      if (distance > nearRadius) {
        final dirX = dx / distance;
        final dirY = dy / distance;
        final dot = (dirX * normFacingX + dirY * normFacingY).clamp(-1.0, 1.0);
        final angle = acos(dot);
        if (angle > halfAngleRad) continue;
      }

      final targetX = originX + dx;
      final targetY = originY + dy;
      if (_hasLineOfSight(world, originX, originY, targetX, targetY, z)) {
        visible.add((x: targetX, y: targetY));
      }
    }
  }
  return visible;
}

/// Ob [x1]/[y1] von [x0]/[y0] aus sichtbar ist — `false`, wenn ein Tile
/// STRIKT dazwischen (nicht Ursprung, nicht Ziel selbst) die Sicht
/// blockiert. Das Ziel-Tile ist immer "sichtbar", wenn man bis dorthin
/// sieht — man sieht die Felswand, nur nicht, was dahinter liegt.
bool _hasLineOfSight(World world, int x0, int y0, int x1, int y1, int z) {
  final line = _bresenhamLine(x0, y0, x1, y1);
  for (var i = 1; i < line.length - 1; i++) {
    final point = line[i];
    if (world.tileAt(point.x, point.y, z).type.blocksSight) return false;
  }
  return true;
}

/// Klassischer Bresenham-Linienalgorithmus zwischen zwei Tile-Koordinaten,
/// inklusive Start- und Endpunkt.
List<({int x, int y})> _bresenhamLine(int x0, int y0, int x1, int y1) {
  final points = <({int x, int y})>[];
  var x = x0;
  var y = y0;
  final dx = (x1 - x0).abs();
  final dy = -(y1 - y0).abs();
  final sx = x0 < x1 ? 1 : -1;
  final sy = y0 < y1 ? 1 : -1;
  var err = dx + dy;

  while (true) {
    points.add((x: x, y: y));
    if (x == x1 && y == y1) break;
    final e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y += sy;
    }
  }
  return points;
}
