import 'dart:ui';

import 'package:flame/components.dart';

/// Zeichnet eine Umrandung um ein Welt-Tile — genutzt für Hover-Anzeige und
/// Interaktions-/Selektions-Hervorhebung (Roadmap UI-03: "Hover-Highlight
/// und Selected-Highlight trennen"). Rendert nichts, wenn [tileProvider]
/// `null` liefert (kein Hover, keine aktive Interaktion), damit die Karte
/// nicht ständig eine bedeutungslose Umrandung zeigt.
class TileHighlightComponent extends PositionComponent {
  final ({int x, int y})? Function() tileProvider;
  final double tileSize;
  final Color color;
  final double strokeWidth;

  TileHighlightComponent({
    required this.tileProvider,
    required this.tileSize,
    this.color = const Color(0xFFFFEB3B),
    this.strokeWidth = 3,
  });

  final Paint _paint = Paint()..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    final tile = tileProvider();
    if (tile == null) return;

    final rect = Rect.fromLTWH(
      tile.x * tileSize,
      tile.y * tileSize,
      tileSize,
      tileSize,
    );

    _paint
      ..color = color
      ..strokeWidth = strokeWidth;
    canvas.drawRect(rect.deflate(strokeWidth / 2), _paint);
  }
}
