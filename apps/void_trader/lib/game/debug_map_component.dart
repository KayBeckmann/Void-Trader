import 'dart:ui';

import 'package:flame/components.dart';
import 'package:vt_content/vt_content.dart';
// Alias nötig: flame/components.dart bringt über die Kamera ebenfalls eine
// Klasse `World` mit — Namenskollision mit vt_world.World. Component/
// FlameGame definieren zudem einen `world`-Getter, daher heißt das Feld
// unten bewusst `gameWorld` statt `world`.
import 'package:vt_world/vt_world.dart' as vt_world;

/// Rendert ein rechteckiges Fenster aus Welt-Tile-Koordinaten (eine
/// z-Ebene) inklusive des dort persistierten Wasserstands
/// ([vt_world.Tile.waterLevel]) als einfaches Debug-Grid.
///
/// Arbeitet bewusst in Welt- statt Chunk-Koordinaten: das Fenster kann so
/// frei über Chunk-Grenzen hinweg positioniert werden, z.B. zentriert auf
/// den Weltursprung (siehe VoidTraderGame) statt an eine einzelne
/// Chunk-Kachel gebunden zu sein. Der Wasserstand kommt direkt aus der Welt
/// (siehe `WorldFluidBridge` in vt_physics) statt aus einem separaten,
/// losgelösten Demo-Grid.
class DebugMapComponent extends PositionComponent {
  final vt_world.World gameWorld;
  final int originX;
  final int originY;
  final int tileWidth;
  final int tileHeight;
  final int z;
  final double tileSize;

  DebugMapComponent({
    required this.gameWorld,
    required this.originX,
    required this.originY,
    required this.tileWidth,
    required this.tileHeight,
    required this.z,
    this.tileSize = 16,
  }) : super(size: Vector2(tileWidth * tileSize, tileHeight * tileSize));

  final Paint _tilePaint = Paint();
  final Paint _waterPaint = Paint();
  final Paint _buildingPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    for (var y = 0; y < tileHeight; y++) {
      for (var x = 0; x < tileWidth; x++) {
        final worldX = originX + x;
        final worldY = originY + y;
        final tile = gameWorld.tileAt(worldX, worldY, z);
        final rect = Rect.fromLTWH(
          x * tileSize,
          y * tileSize,
          tileSize,
          tileSize,
        );

        _tilePaint.color = tileColor(tile.type);
        canvas.drawRect(rect, _tilePaint);

        if (tile.waterLevel > 0) {
          final alpha = (tile.waterLevel.clamp(0.0, 1.0) * 200).round();
          _waterPaint.color = Color.fromARGB(alpha, 0x21, 0x96, 0xF3);
          canvas.drawRect(rect, _waterPaint);
        }

        final building = gameWorld.buildingAt(worldX, worldY, z);
        if (building != null) {
          _buildingPaint.color = buildingColor(building);
          canvas.drawRect(rect.deflate(1), _buildingPaint);
        }
      }
    }
  }

  /// Debug-Farbe je Tile-Typ. Wird durch echte Pixel-Art in einer späteren
  /// Phase ersetzt.
  static Color tileColor(vt_world.TileType type) {
    switch (type) {
      case vt_world.TileType.grass:
        return const Color(0xFF4CAF50);
      case vt_world.TileType.dirt:
        return const Color(0xFF8D6E63);
      case vt_world.TileType.stone:
        return const Color(0xFF9E9E9E);
      case vt_world.TileType.water:
        return const Color(0xFF2196F3);
      case vt_world.TileType.forest:
        return const Color(0xFF2E7D32);
      case vt_world.TileType.farmland:
        return const Color(0xFFBCAAA4);
      case vt_world.TileType.path:
        return const Color(0xFFD7CCC8);
      case vt_world.TileType.rockWall:
        return const Color(0xFF424242);
      case vt_world.TileType.empty:
        return const Color(0xFF000000);
      case vt_world.TileType.caveEntrance:
        return const Color(0xFF6A1B9A);
      case vt_world.TileType.ore:
        return const Color(0xFFFFA000);
    }
  }

  /// Debug-Umrandungsfarbe je Gebäudetyp. Wird durch echte Pixel-Art in
  /// einer späteren Phase ersetzt.
  static Color buildingColor(BuildingType type) {
    switch (type) {
      case BuildingType.wall:
        return const Color(0xFF3E2723);
      case BuildingType.workbench:
        return const Color(0xFFFFEB3B);
      case BuildingType.market:
        return const Color(0xFF00BFA5);
    }
  }
}
