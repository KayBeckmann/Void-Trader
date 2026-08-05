import 'dart:ui';

import 'package:flame/components.dart';
import 'package:vt_physics/vt_physics.dart';
// Alias nötig: flame/components.dart bringt über die Kamera ebenfalls eine
// Klasse `World` mit — Namenskollision mit vt_world.World. Component/
// FlameGame definieren zudem einen `world`-Getter, daher heißt das Feld
// unten bewusst `gameWorld` statt `world`.
import 'package:vt_world/vt_world.dart' as vt_world;

/// Rendert einen einzelnen Chunk (eine z-Ebene) plus den zugehörigen
/// [FluidGrid]-Wasserzustand als einfaches Debug-Grid.
///
/// Dient laut Roadmap-Empfehlung als Zwischenschritt vor Spielerfigur und
/// echten Sprites: erst sehen, dass Tiles + Wasser korrekt zusammenspielen,
/// bevor Steuerung und Grafik dazukommen.
class DebugMapComponent extends PositionComponent {
  final vt_world.World gameWorld;
  final vt_world.ChunkCoord chunkCoord;
  final int z;
  final FluidGrid fluidGrid;
  final double tileSize;

  DebugMapComponent({
    required this.gameWorld,
    required this.chunkCoord,
    required this.z,
    required this.fluidGrid,
    this.tileSize = 16,
  }) : assert(
         fluidGrid.width == vt_world.Chunk.size &&
             fluidGrid.height == vt_world.Chunk.size,
         'fluidGrid muss dieselbe Größe wie ein Chunk haben '
         '(${vt_world.Chunk.size}x${vt_world.Chunk.size})',
       ),
       super(size: Vector2.all(vt_world.Chunk.size * tileSize));

  final Paint _tilePaint = Paint();
  final Paint _waterPaint = Paint();

  @override
  void render(Canvas canvas) {
    final chunk = gameWorld.getOrCreateChunk(chunkCoord);
    final layer = chunk.layerAt(z);

    for (var y = 0; y < vt_world.Chunk.size; y++) {
      for (var x = 0; x < vt_world.Chunk.size; x++) {
        final rect = Rect.fromLTWH(
          x * tileSize,
          y * tileSize,
          tileSize,
          tileSize,
        );

        _tilePaint.color = tileColor(layer.tileAt(x, y).type);
        canvas.drawRect(rect, _tilePaint);

        final waterLevel = fluidGrid.cellAt(x, y).waterLevel;
        if (waterLevel > 0) {
          final alpha = (waterLevel.clamp(0.0, 1.0) * 200).round();
          _waterPaint.color = Color.fromARGB(alpha, 0x21, 0x96, 0xF3);
          canvas.drawRect(rect, _waterPaint);
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
    }
  }
}
