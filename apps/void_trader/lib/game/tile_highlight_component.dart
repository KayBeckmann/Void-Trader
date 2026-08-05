import 'dart:ui';

import 'package:flame/components.dart';

/// Zeichnet eine Umrandung um das Tile unter [positionProvider] — die
/// visuelle Entsprechung zum kontextabhängigen HUD-Hinweis
/// (`VoidTraderGame.currentInteractionHint`): der Spieler soll nicht nur
/// lesen, sondern auch sehen, worauf sich eine mögliche Interaktion
/// bezieht. Rendert nur, wenn [isActiveProvider] `true` liefert, damit die
/// Karte nicht ständig eine Umrandung ohne Bedeutung zeigt.
class TileHighlightComponent extends PositionComponent {
  final Vector2 Function() positionProvider;
  final bool Function() isActiveProvider;
  final double tileSize;
  final Color color;

  TileHighlightComponent({
    required this.positionProvider,
    required this.isActiveProvider,
    required this.tileSize,
    this.color = const Color(0xFFFFEB3B),
  });

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  void render(Canvas canvas) {
    if (!isActiveProvider()) return;

    final position = positionProvider();
    final tileX = (position.x / tileSize).floor();
    final tileY = (position.y / tileSize).floor();
    final rect = Rect.fromLTWH(
      tileX * tileSize,
      tileY * tileSize,
      tileSize,
      tileSize,
    );

    _paint.color = color;
    canvas.drawRect(rect.deflate(1.5), _paint);
  }
}
