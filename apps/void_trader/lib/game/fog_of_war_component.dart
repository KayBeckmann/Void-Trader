import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
// Alias nötig: siehe debug_map_component.dart — Namenskollision mit
// flame/components.dart World + Component/FlameGame world-Getter.
import 'package:vt_world/vt_world.dart' as vt_world;

/// Verdunkelt das mitscrollende Kartenfenster anhand des
/// [vt_world.ExplorationTracker] (Roadmap FOW-04: "Fog-Renderer") — liegt
/// über [TileSpriteMapComponent]/[DebugMapComponent], aber unter
/// Tile-Hervorhebung, Spieler und NPCs (siehe VoidTraderGame.onLoad), damit
/// die eigene Figur nie im Nebel verschwindet.
///
/// [vt_world.VisibilityState.unseen] wird stark abgedunkelt,
/// [vt_world.VisibilityState.seenButNotVisible] leicht abgedunkelt
/// (bekannt, aber gerade nicht im Blick), [vt_world.VisibilityState.visible]
/// bekommt kein Overlay.
class FogOfWarComponent extends PositionComponent {
  final vt_world.ExplorationTracker explorationTracker;
  final Vector2 Function() centerProvider;
  final int viewRadiusTiles;
  final double tileSize;

  /// Aktuelle z-Ebene (Roadmap MOV-03/Kays Feedback 2026-09-27: Fog of War
  /// getrennt je Ebene) — derselbe Provider wie bei [TileSpriteMapComponent.
  /// zProvider]/[DebugMapComponent.zProvider], damit Rendering und
  /// Exploration-Abfrage nie auseinanderlaufen.
  final int Function() zProvider;

  FogOfWarComponent({
    required this.explorationTracker,
    required this.centerProvider,
    required this.viewRadiusTiles,
    required this.zProvider,
    this.tileSize = 32,
  }) : assert(viewRadiusTiles > 0, 'viewRadiusTiles muss positiv sein');

  final Paint _unseenPaint = Paint()..color = const Color(0xFF05070A);
  final Paint _seenButNotVisiblePaint = Paint()..color = const Color(0xB005070A);

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
        final state = explorationTracker.stateAt(worldX, worldY, z: z);
        if (state == vt_world.VisibilityState.visible) continue;

        final rect = Rect.fromLTWH(
          worldX * tileSize,
          worldY * tileSize,
          tileSize,
          tileSize,
        );
        canvas.drawRect(
          rect,
          state == vt_world.VisibilityState.unseen ? _unseenPaint : _seenButNotVisiblePaint,
        );
      }
    }
  }
}
