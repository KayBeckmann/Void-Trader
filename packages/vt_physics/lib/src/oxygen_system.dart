import 'dart:collection';

import 'package:vt_world/vt_world.dart';

/// Ergebnis einer begrenzten Zusammenhangs-Prüfung für Atmosphäre/Sauerstoff
/// (Roadmap Phase 3: "Höhlen/Innenräume können begrenzte Luft besitzen").
enum OxygenRegionState {
  /// Oberfläche — hat per Definition immer freie Luft.
  openSurface,

  /// Der zusammenhängende offene Bereich hat innerhalb des Suchfensters
  /// den Rand des geladenen/erkundeten Bereichs erreicht — wird als
  /// (wahrscheinlich) an die Außenwelt angeschlossen behandelt.
  open,

  /// Der zusammenhängende offene Bereich endet vollständig innerhalb des
  /// Suchfensters, umschlossen von solidem Gestein — versiegelt.
  sealed,
}

/// Prüft, ob ein zusammenhängender begehbarer Bereich in einer Höhlenebene
/// versiegelt ist oder (wahrscheinlich) Kontakt zur Außenwelt hat.
///
/// Bewusst chunk-basiert budgetiert (siehe Roadmap-Designregel Phase 3):
/// Die Suche bricht spätestens nach [OxygenSystem.regionStateAt]s
/// `maxTiles` ab und generiert dabei keine neuen Chunks — sie arbeitet nur
/// auf bereits geladenen Tiles ([World.peekTileAt]). Das ist die Grundlage
/// für eine spätere echte Sauerstoff-Mechanik (Verbrauch, Lecks,
/// Belüftung), noch ohne selbst Luft zu verbrauchen.
class OxygenSystem {
  final World world;

  const OxygenSystem(this.world);

  /// Klassifiziert den zusammenhängenden offenen Bereich um
  /// (startX, startY, z).
  ///
  /// Auf der Oberflächen-Ebene wird immer [OxygenRegionState.openSurface]
  /// geliefert, ohne zu suchen. Für tiefere Ebenen wird per
  /// Breitensuche über begehbare Nachbar-Tiles expandiert:
  /// - Trifft die Suche auf ein noch nicht geladenes Tile oder erschöpft
  ///   das [maxTiles]-Budget, gilt der Bereich als [OxygenRegionState.open]
  ///   (wir wissen es nicht sicher, nehmen aber Anschluss an weiteren Raum
  ///   an statt fälschlich "versiegelt" zu melden).
  /// - Ist die Suche vollständig innerhalb geladener, solider Grenzen
  ///   abgeschlossen, gilt der Bereich als [OxygenRegionState.sealed].
  OxygenRegionState regionStateAt(
    int startX,
    int startY,
    int z, {
    int maxTiles = 400,
  }) {
    if (z == ZLevel.surface) return OxygenRegionState.openSurface;

    final start = world.peekTileAt(startX, startY, z);
    if (start == null || start.isSolid) return OxygenRegionState.sealed;

    final visited = <({int x, int y})>{(x: startX, y: startY)};
    final queue = Queue<({int x, int y})>()..add((x: startX, y: startY));

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final neighbor in _neighborsOf(current.x, current.y)) {
        if (visited.contains(neighbor)) continue;

        final tile = world.peekTileAt(neighbor.x, neighbor.y, z);
        if (tile == null) {
          // Rand des geladenen/erkundeten Bereichs erreicht.
          return OxygenRegionState.open;
        }
        if (tile.isSolid) continue;

        if (visited.length >= maxTiles) {
          return OxygenRegionState.open;
        }
        visited.add(neighbor);
        queue.add(neighbor);
      }
    }

    return OxygenRegionState.sealed;
  }

  Iterable<({int x, int y})> _neighborsOf(int x, int y) sync* {
    yield (x: x + 1, y: y);
    yield (x: x - 1, y: y);
    yield (x: x, y: y + 1);
    yield (x: x, y: y - 1);
  }
}
