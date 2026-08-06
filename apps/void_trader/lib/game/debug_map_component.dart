import 'dart:ui';

import 'package:flame/components.dart';
import 'package:vt_content/vt_content.dart';
// Alias nötig: flame/components.dart bringt über die Kamera ebenfalls eine
// Klasse `World` mit — Namenskollision mit vt_world.World. Component/
// FlameGame definieren zudem einen `world`-Getter, daher heißt das Feld
// unten bewusst `gameWorld` statt `world`.
import 'package:vt_world/vt_world.dart' as vt_world;

/// Rendert ein Fenster aus Welt-Tile-Koordinaten (eine z-Ebene) inklusive
/// des dort persistierten Wasserstands ([vt_world.Tile.waterLevel]) als
/// einfaches Debug-Grid aus Farbflächen — zentriert sich jeden Frame neu
/// um [centerProvider], genau wie `TileSpriteMapComponent`, damit beide
/// exakt dasselbe (mitscrollende) Fenster zeigen.
///
/// Seit der Sofort-Korrektur nach Webpreview 2026-08-05 ist dies **nicht
/// mehr die normale Spielansicht** (das übernimmt `TileSpriteMapComponent`),
/// sondern ein schaltbares Debug-Overlay — siehe [enabled].
class DebugMapComponent extends PositionComponent {
  final vt_world.World gameWorld;
  final Vector2 Function() centerProvider;
  final int viewRadiusTiles;

  /// Liefert die aktuell darzustellende z-Ebene (Roadmap MOV-03) — eine
  /// Funktion statt eines festen Werts, analog zu [centerProvider] und
  /// [TileSpriteMapComponent.zProvider].
  final int Function() zProvider;
  final double tileSize;

  /// Ob das Debug-Overlay (Tile-Farben + Wasser + Gebäude-Umrandung)
  /// gezeichnet wird. Standardmäßig aus, da die normale Ansicht jetzt
  /// `TileSpriteMapComponent` ist — per Taste umschaltbar (VoidTraderGame).
  bool enabled;

  DebugMapComponent({
    required this.gameWorld,
    required this.centerProvider,
    required this.viewRadiusTiles,
    required this.zProvider,
    this.tileSize = 16,
    this.enabled = false,
  }) : assert(viewRadiusTiles > 0, 'viewRadiusTiles muss positiv sein');

  final Paint _tilePaint = Paint();
  final Paint _waterPaint = Paint();
  final Paint _buildingPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    if (!enabled) return;

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
      case vt_world.TileType.slope:
        return const Color(0xFFA1887F);
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
      case BuildingType.landingPad:
        return const Color(0xFF607D8B);
      case BuildingType.storage:
        return const Color(0xFF8D6E63);
    }
  }
}
