import 'package:vt_world/vt_world.dart';

import 'fluid_grid.dart';

/// Verbindet die Wasser-Simulation ([FluidGrid]) mit den tatsächlichen
/// Welt-Tiles aus vt_world: Solidität kommt aus [Tile.isSolid]
/// (Solid/Terrain), der Wasserstand wird persistent in [Tile.waterLevel]
/// gehalten (Roadmap Phase 3).
///
/// Arbeitet bewusst nur auf bereits geladenen Chunks ([World.peekTileAt]) —
/// unsichtbare/unbesuchte Bereiche werden durch die Fluid-Simulation nicht
/// nebenbei generiert ("chunk-basiert und budgetiert", siehe Roadmap
/// Designregel für Phase 3).
class WorldFluidBridge {
  final World world;
  final int z;

  const WorldFluidBridge(this.world, this.z);

  /// Baut ein [FluidGrid]-Fenster aus der Welt. Tiles in nicht geladenen
  /// Chunks werden als massiv/solide behandelt, damit dort kein Wasser
  /// "aus dem Nichts" entsteht oder verschwindet.
  FluidGrid buildGrid({
    required int originX,
    required int originY,
    required int width,
    required int height,
  }) {
    final grid = FluidGrid(width, height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final tile = world.peekTileAt(originX + x, originY + y, z);
        if (tile == null || tile.isSolid) {
          grid.setSolid(x, y, solid: true);
        } else if (tile.waterLevel > 0) {
          grid.addWater(x, y, tile.waterLevel);
        }
      }
    }
    return grid;
  }

  /// Schreibt den simulierten Wasserstand aus [grid] zurück in die Welt.
  /// Tiles in nicht geladenen Chunks oder solide Tiles werden dabei
  /// übersprungen (letztere dürfen laut [Tile]-Invariante nie Wasser
  /// halten und wurden beim Bauen des Grids ohnehin als solide markiert).
  void applyGrid(FluidGrid grid, {required int originX, required int originY}) {
    for (var y = 0; y < grid.height; y++) {
      for (var x = 0; x < grid.width; x++) {
        final worldX = originX + x;
        final worldY = originY + y;
        final tile = world.peekTileAt(worldX, worldY, z);
        if (tile == null || tile.isSolid) continue;

        final simulatedLevel = grid.cellAt(x, y).waterLevel;
        if (simulatedLevel == tile.waterLevel) continue;
        world.setTileAt(worldX, worldY, z, tile.copyWith(waterLevel: simulatedLevel));
      }
    }
  }

  /// Bequemlichkeitsmethode: baut das Grid, simuliert einen Schritt und
  /// schreibt das Ergebnis zurück.
  void step({
    required int originX,
    required int originY,
    required int width,
    required int height,
    double flowRate = 0.5,
  }) {
    final grid = buildGrid(originX: originX, originY: originY, width: width, height: height);
    grid.step(flowRate: flowRate);
    applyGrid(grid, originX: originX, originY: originY);
  }
}
