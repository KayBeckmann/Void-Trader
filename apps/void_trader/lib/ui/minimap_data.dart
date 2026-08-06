import 'package:vt_world/vt_world.dart' as vt_world;

/// Grobe Terrain-Kategorie fürs Minimap (Roadmap HUD-13: "Terrain grob
/// farbcodiert: Wasser, Gras/Land, Wald, Fels/Berg, Gebäude/Startzone").
/// Bewusst wenige Kategorien statt aller [vt_world.TileType]-Werte — das
/// Minimap soll auf einen Blick lesbar sein, nicht die volle Detailkarte
/// verkleinert zeigen.
enum MinimapTerrain {
  /// Noch nicht entdeckt — Minimap "darf nicht lügen" (Roadmap), zeigt
  /// hier bewusst keine Terrainfarbe.
  unknown,
  water,
  land,
  forest,
  rock,
  building,
}

/// Ordnet einen [vt_world.TileType] (+ ob dort ein Gebäude steht) einer
/// [MinimapTerrain]-Kategorie zu. Reine Funktion ohne Rendering-Bezug,
/// damit sie ohne Widget-Test/Canvas prüfbar ist.
MinimapTerrain minimapTerrainFor(vt_world.TileType type, {bool hasBuilding = false}) {
  if (hasBuilding) return MinimapTerrain.building;
  switch (type) {
    case vt_world.TileType.water:
      return MinimapTerrain.water;
    case vt_world.TileType.forest:
      return MinimapTerrain.forest;
    case vt_world.TileType.stone:
    case vt_world.TileType.rockWall:
    case vt_world.TileType.ore:
      return MinimapTerrain.rock;
    case vt_world.TileType.grass:
    case vt_world.TileType.dirt:
    case vt_world.TileType.farmland:
    case vt_world.TileType.path:
    case vt_world.TileType.empty:
    case vt_world.TileType.caveEntrance:
    case vt_world.TileType.slope:
      return MinimapTerrain.land;
  }
}

/// Eine einzelne Minimap-Zelle: grobe Terrainfarbe plus Sichtbarkeitsstatus
/// (Roadmap FOW-01), damit der Renderer unentdeckte/nur-bekannte/aktuell
/// sichtbare Bereiche unterschiedlich abdunkeln kann.
class MinimapCell {
  final MinimapTerrain terrain;
  final vt_world.VisibilityState visibility;

  const MinimapCell({required this.terrain, required this.visibility});
}

/// Baut ein quadratisches Minimap-Raster um [centerX]/[centerY] (Roadmap
/// HUD-13) — budgetiert durch [radiusTiles] statt die komplette Welt zu
/// scannen. Fragt für [vt_world.VisibilityState.unseen]-Tiles absichtlich
/// NIE das echte Terrain ab (auch wenn der Chunk bereits generiert wäre) —
/// so kann die Minimap strukturell nicht "lügen" und unentdeckte Karte
/// verraten, und es wird keine Chunk-Generierung für unentdeckte Bereiche
/// ausgelöst.
List<List<MinimapCell>> buildMinimapGrid({
  required vt_world.World world,
  required vt_world.ExplorationTracker explorationTracker,
  required int centerX,
  required int centerY,
  required int z,
  required int radiusTiles,
}) {
  return List.generate(radiusTiles * 2 + 1, (dy) {
    final worldY = centerY - radiusTiles + dy;
    return List.generate(radiusTiles * 2 + 1, (dx) {
      final worldX = centerX - radiusTiles + dx;
      final visibility = explorationTracker.stateAt(worldX, worldY);
      if (visibility == vt_world.VisibilityState.unseen) {
        return const MinimapCell(
          terrain: MinimapTerrain.unknown,
          visibility: vt_world.VisibilityState.unseen,
        );
      }
      final tile = world.peekTileAt(worldX, worldY, z);
      final building = world.buildingAt(worldX, worldY, z);
      return MinimapCell(
        terrain: tile == null
            ? MinimapTerrain.unknown
            : minimapTerrainFor(tile.type, hasBuilding: building != null),
        visibility: visibility,
      );
    });
  });
}
