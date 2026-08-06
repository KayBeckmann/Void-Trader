import 'dart:ui';

import 'package:flame/components.dart';
import 'package:vt_content/vt_content.dart';
// Alias nötig: siehe debug_map_component.dart — Namenskollision mit
// flame/components.dart World + Component/FlameGame world-Getter.
import 'package:vt_world/vt_world.dart' as vt_world;

import 'debug_map_component.dart';

/// Normale Spielansicht: rendert Pixel-Art-Sprites für ein Fenster aus
/// Welt-Tiles, das sich **jeden Frame neu um [centerProvider] zentriert**
/// — die Welt scrollt so unter der (von der Kamera immer zentrierten)
/// Spielfigur, statt an ein festes Fenster um den Weltursprung gebunden zu
/// sein. Jedes Welt-Tile liegt auf einer festen, absoluten Pixel-Position
/// (`worldX * tileSize`), nicht relativ zu einem Fenster-Ursprung — genau
/// diese Absolutheit macht das Scrollen möglich, ohne beim Verlassen eines
/// vorab berechneten Bereichs ins Leere zu laufen.
///
/// [DebugMapComponent] bleibt daneben als schaltbares Debug-Overlay
/// erhalten (siehe VoidTraderGame) und nutzt dasselbe Prinzip.
class TileSpriteMapComponent extends PositionComponent {
  final vt_world.World gameWorld;
  final Vector2 Function() centerProvider;
  final int viewRadiusTiles;

  /// Liefert die aktuell darzustellende z-Ebene (Roadmap MOV-03: "Kamera/
  /// Rendering muss die aktuelle z-Ebene visuell kommunizieren"). Eine
  /// Funktion statt eines festen Werts, weil der Spieler über Rampen
  /// zwischen Ebenen wechseln kann — analog zu [centerProvider].
  final int Function() zProvider;
  final double tileSize;

  TileSpriteMapComponent({
    required this.gameWorld,
    required this.centerProvider,
    required this.viewRadiusTiles,
    required this.zProvider,
    this.tileSize = 32,
  }) : assert(viewRadiusTiles > 0, 'viewRadiusTiles muss positiv sein');

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
    vt_world.TileType.slope: 'tiles/slope.png',
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
    final center = centerProvider();
    final centerTileX = (center.x / tileSize).floor();
    final centerTileY = (center.y / tileSize).floor();
    final originX = centerTileX - viewRadiusTiles;
    final originY = centerTileY - viewRadiusTiles;
    final span = viewRadiusTiles * 2;
    final z = zProvider();

    for (var dy = 0; dy <= span; dy++) {
      for (var dx = 0; dx <= span; dx++) {
        final worldX = originX + dx;
        final worldY = originY + dy;
        final tile = gameWorld.tileAt(worldX, worldY, z);
        final rect = Rect.fromLTWH(
          worldX * tileSize,
          worldY * tileSize,
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
