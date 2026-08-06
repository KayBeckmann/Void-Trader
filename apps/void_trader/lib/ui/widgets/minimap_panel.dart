import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vt_world/vt_world.dart' as vt_world;

import '../design_tokens.dart';
import '../minimap_data.dart';

/// Minimap-Panel rechts oben (Roadmap HUD-13: "Minimap V1") — zeigt
/// Spielerposition, grobe Terrainfarben und Fog-of-War-Zustände um den
/// Spieler. Bekommt ein fertiges, bereits budgetiertes Raster
/// ([buildMinimapGrid]) statt selbst auf die Welt zuzugreifen — bleibt so
/// mit Beispieldaten testbar.
class MinimapPanel extends StatelessWidget {
  final List<List<MinimapCell>> grid;

  /// Blickrichtung des Spielers (muss kein Einheitsvektor sein) — steuert
  /// den kleinen Richtungspfeil in der Mitte. `null` blendet den Pfeil aus.
  final double facingX;
  final double facingY;

  final double size;

  const MinimapPanel({
    super.key,
    required this.grid,
    required this.facingX,
    required this.facingY,
    this.size = 148,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: VtColors.panelBackground,
        borderRadius: BorderRadius.circular(VtRadii.panel),
        border: Border.all(color: VtColors.panelBorder),
      ),
      child: CustomPaint(
        painter: _MinimapPainter(grid: grid, facingX: facingX, facingY: facingY),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final List<List<MinimapCell>> grid;
  final double facingX;
  final double facingY;

  _MinimapPainter({required this.grid, required this.facingX, required this.facingY});

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty) return;
    final rows = grid.length;
    final cols = grid[0].length;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
    final paint = Paint();

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final cell = grid[y][x];
        paint.color = _colorFor(cell);
        canvas.drawRect(
          Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth + 0.5, cellHeight + 0.5),
          paint,
        );
      }
    }

    // Spielerposition ist per Konstruktion immer die Mitte des Rasters
    // (siehe buildMinimapGrid: centerX/centerY).
    final centerPx = Offset(size.width / 2, size.height / 2);
    final playerPaint = Paint()..color = VtColors.accentAmber;
    canvas.drawCircle(centerPx, min(cellWidth, cellHeight) * 0.9, playerPaint);

    _drawFacingArrow(canvas, centerPx, min(cellWidth, cellHeight));
  }

  void _drawFacingArrow(Canvas canvas, Offset center, double cellSize) {
    final length = sqrt(facingX * facingX + facingY * facingY);
    if (length == 0) return;
    final dirX = facingX / length;
    final dirY = facingY / length;

    final tip = center + Offset(dirX, dirY) * (cellSize * 2.2);
    final baseCenter = center + Offset(dirX, dirY) * (cellSize * 0.9);
    // Senkrecht zur Blickrichtung für die Pfeilbasis.
    final perpX = -dirY;
    final perpY = dirX;
    final baseWidth = cellSize * 0.8;
    final baseLeft = baseCenter + Offset(perpX, perpY) * baseWidth;
    final baseRight = baseCenter - Offset(perpX, perpY) * baseWidth;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = VtColors.accentCyan);
  }

  Color _colorFor(MinimapCell cell) {
    final base = switch (cell.terrain) {
      MinimapTerrain.unknown => const Color(0xFF05070A),
      MinimapTerrain.water => const Color(0xFF2196F3),
      MinimapTerrain.land => const Color(0xFF4CAF50),
      MinimapTerrain.forest => const Color(0xFF1B5E20),
      MinimapTerrain.rock => const Color(0xFF8D8D8D),
      MinimapTerrain.building => VtColors.accentAmber,
    };
    if (cell.visibility == vt_world.VisibilityState.seenButNotVisible) {
      // Bekannt, aber gerade nicht im Blick — gedimmt statt voller Farbe.
      return Color.alphaBlend(base.withValues(alpha: 0.45), const Color(0xFF05070A));
    }
    return base;
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) {
    return oldDelegate.grid != grid ||
        oldDelegate.facingX != facingX ||
        oldDelegate.facingY != facingY;
  }
}
