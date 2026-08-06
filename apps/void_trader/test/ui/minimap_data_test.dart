import 'package:flutter_test/flutter_test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_world/vt_world.dart' as vt_world;
import 'package:void_trader/ui/minimap_data.dart';

void main() {
  group('minimapTerrainFor', () {
    test('ordnet Wasser/Wald/Fels ihren eigenen Kategorien zu', () {
      expect(minimapTerrainFor(vt_world.TileType.water), MinimapTerrain.water);
      expect(minimapTerrainFor(vt_world.TileType.forest), MinimapTerrain.forest);
      expect(minimapTerrainFor(vt_world.TileType.stone), MinimapTerrain.rock);
      expect(minimapTerrainFor(vt_world.TileType.rockWall), MinimapTerrain.rock);
      expect(minimapTerrainFor(vt_world.TileType.ore), MinimapTerrain.rock);
    });

    test('ordnet begehbares Gelände "land" zu', () {
      expect(minimapTerrainFor(vt_world.TileType.grass), MinimapTerrain.land);
      expect(minimapTerrainFor(vt_world.TileType.dirt), MinimapTerrain.land);
      expect(minimapTerrainFor(vt_world.TileType.path), MinimapTerrain.land);
      expect(minimapTerrainFor(vt_world.TileType.slope), MinimapTerrain.land);
    });

    test('Gebäude überschreibt die Terrainkategorie', () {
      expect(
        minimapTerrainFor(vt_world.TileType.grass, hasBuilding: true),
        MinimapTerrain.building,
      );
    });
  });

  group('buildMinimapGrid (Roadmap HUD-13)', () {
    test('liefert ein (2*radius+1)-großes quadratisches Raster', () {
      final world = vt_world.World(1);
      final tracker = vt_world.ExplorationTracker();

      final grid = buildMinimapGrid(
        world: world,
        explorationTracker: tracker,
        centerX: 0,
        centerY: 0,
        z: vt_world.ZLevel.surface,
        radiusTiles: 3,
      );

      expect(grid.length, 7);
      expect(grid.every((row) => row.length == 7), isTrue);
    });

    test('unentdeckte Tiles sind unknown/unseen, auch wenn das Terrain existiert', () {
      final world = vt_world.World(1);
      final tracker = vt_world.ExplorationTracker(); // nichts entdeckt

      final grid = buildMinimapGrid(
        world: world,
        explorationTracker: tracker,
        centerX: 0,
        centerY: 0,
        z: vt_world.ZLevel.surface,
        radiusTiles: 2,
      );

      for (final row in grid) {
        for (final cell in row) {
          expect(cell.terrain, MinimapTerrain.unknown);
          expect(cell.visibility, vt_world.VisibilityState.unseen);
        }
      }
    });

    test('entdeckte Tiles zeigen ihre echte Terrainkategorie', () {
      final world = vt_world.World(1);
      world.setTileAt(0, 0, vt_world.ZLevel.surface, const vt_world.Tile(vt_world.TileType.water));
      final tracker = vt_world.ExplorationTracker()..update({(x: 0, y: 0)});

      final grid = buildMinimapGrid(
        world: world,
        explorationTracker: tracker,
        centerX: 0,
        centerY: 0,
        z: vt_world.ZLevel.surface,
        radiusTiles: 1,
      );

      // (0,0) liegt in der Mitte des 3x3-Rasters (radius 1).
      final centerCell = grid[1][1];
      expect(centerCell.terrain, MinimapTerrain.water);
      expect(centerCell.visibility, vt_world.VisibilityState.visible);
    });

    test('ein Gebäude auf entdecktem Boden zeigt "building" statt Terrain', () {
      final world = vt_world.World(1);
      world.setTileAt(0, 0, vt_world.ZLevel.surface, const vt_world.Tile(vt_world.TileType.grass));
      world.placeBuildingAt(0, 0, vt_world.ZLevel.surface, BuildingType.workbench);
      final tracker = vt_world.ExplorationTracker()..update({(x: 0, y: 0)});

      final grid = buildMinimapGrid(
        world: world,
        explorationTracker: tracker,
        centerX: 0,
        centerY: 0,
        z: vt_world.ZLevel.surface,
        radiusTiles: 1,
      );

      expect(grid[1][1].terrain, MinimapTerrain.building);
    });
  });
}
