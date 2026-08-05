import 'dart:ui';

import 'package:flame/components.dart';
import 'package:vt_content/vt_content.dart';
// Alias nötig: siehe debug_map_component.dart — Namenskollision mit
// flame/components.dart World + Component/FlameGame world-Getter.
import 'package:vt_world/vt_world.dart' as vt_world;

import 'debug_map_component.dart';

/// Normale Spielansicht (Sofort-Korrektur nach Webpreview 2026-08-05):
/// rendert Pixel-Art-Sprites statt Debug-Farbflächen für dasselbe
/// Welt-Tile-Fenster wie [DebugMapComponent]. Wasserstand und platzierte
/// Gebäude werden weiterhin direkt mit angezeigt — [DebugMapComponent]
/// bleibt daneben als schaltbares Debug-Overlay erhalten (siehe
/// VoidTraderGame).
class TileSpriteMapComponent extends PositionComponent {
  final vt_world.World gameWorld;
  final int originX;
  final int originY;
  final int tileWidth;
  final int tileHeight;
  final int z;
  final double tileSize;

  TileSpriteMapComponent({
    required this.gameWorld,
    required this.originX,
    required this.originY,
    required this.tileWidth,
    required this.tileHeight,
    required this.z,
    this.tileSize = 32,
  }) : super(size: Vector2(tileWidth * tileSize, tileHeight * tileSize));

  /// Sprite-Dateien je Tile-Typ, relativ zu `Flame.images.prefix`
  /// (`assets/pixel-art/`, siehe VoidTraderGame.onLoad). Quellen/Status
  /// stehen im Manifest (`assets/pixel-art/manifest.json`).
  static const Map<vt_world.TileType, String> tileAssetFiles = {
    vt_world.TileType.grass: 'tiles/grass.png',
    vt_world.TileType.dirt: 'tiles/dirt.png',
    vt_world.TileType.stone: 'tiles/stone.png',
    vt_world.TileType.water: 'tiles/water.png',
    vt_world.TileType.forest: 'tiles/forest.png',
    vt_world.TileType.farmland: 'tiles/farmland.png',
    vt_world.TileType.path: 'tiles/path.png',
    vt_world.TileType.rockWall: 'tiles/rock_wall.png',
    vt_world.TileType.empty: 'tiles/empty.png',
    vt_world.TileType.caveEntrance: 'tiles/cave_entrance.png',
    vt_world.TileType.ore: 'tiles/ore.png',
  };

  static const String marketAssetFile = 'buildings/market_kiosk.png';

  late final Map<vt_world.TileType, Sprite> _tileSprites;
  late final Sprite _marketSprite;

  final Paint _waterPaint = Paint();
  final Paint _buildingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _tileSprites = {
      for (final entry in tileAssetFiles.entries) entry.key: await Sprite.load(entry.value),
    };
    _marketSprite = await Sprite.load(marketAssetFile);
  }

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

        _tileSprites[tile.type]?.renderRect(canvas, rect);

        if (tile.waterLevel > 0) {
          final alpha = (tile.waterLevel.clamp(0.0, 1.0) * 140).round();
          _waterPaint.color = Color.fromARGB(alpha, 0x21, 0x96, 0xF3);
          canvas.drawRect(rect, _waterPaint);
        }

        final building = gameWorld.buildingAt(worldX, worldY, z);
        if (building == BuildingType.market) {
          _marketSprite.renderRect(canvas, rect);
        } else if (building != null) {
          // Noch kein Sprite hinterlegt (siehe Asset-Inventar) — Debug-
          // Umrandung als Übergangslösung, bis eigene Grafik existiert.
          _buildingPaint.color = DebugMapComponent.buildingColor(building);
          canvas.drawRect(rect.deflate(1), _buildingPaint);
        }
      }
    }
  }
}
