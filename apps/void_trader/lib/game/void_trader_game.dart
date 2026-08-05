import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:vt_physics/vt_physics.dart';
// Alias nötig: FlameGame definiert selbst einen `world`-Getter/Kamera-World —
// Namenskollision mit vt_world.World.
import 'package:vt_world/vt_world.dart' as vt_world;

import 'debug_map_component.dart';
import 'player_component.dart';

/// Root Flame game.
///
/// Zeigt die [DebugMapComponent] (Tiles + Wasserzustand eines Chunks) plus
/// eine steuerbare [PlayerComponent] mit Kamera-Follow und einem ersten
/// Interaktionswerkzeug (Graben/Abbauen) — Phase 1 der Reboot-Roadmap.
class VoidTraderGame extends FlameGame with HasKeyboardHandlerComponents {
  VoidTraderGame({int seed = 1}) : simulationWorld = vt_world.World(seed);

  final vt_world.World simulationWorld;
  late final FluidGrid debugFluidGrid;
  late final DebugMapComponent map;
  late final PlayerComponent player;

  /// Zähler für erfolgreich abgebaute Tiles (Platzhalter fürs Inventar,
  /// echtes Ressourcensystem folgt in Phase 4).
  int minedResourceCount = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    debugFluidGrid = FluidGrid(vt_world.Chunk.size, vt_world.Chunk.size);
    // Demo-Wasserquelle für den Debug-Screen. Phase 3 koppelt das Fluid-Grid
    // an echte Gelände-Höhen aus vt_world statt an ein leeres Demo-Grid.
    debugFluidGrid.addWater(4, 4, 6);

    map = DebugMapComponent(
      gameWorld: simulationWorld,
      chunkCoord: const vt_world.ChunkCoord(0, 0),
      z: vt_world.ZLevel.surface,
      fluidGrid: debugFluidGrid,
    );

    player = PlayerComponent(position: map.size / 2, onDig: digAt);

    // Wichtig: Komponenten müssen in `world` (nicht direkt via `add()` auf
    // dem Game) liegen, damit sie von der Kamera transformiert werden —
    // sonst folgt die Kamera dem Spieler, aber die Karte bleibt starr.
    await world.addAll([map, player]);
    camera.follow(player);
  }

  /// Versucht, das Tile unter [worldPosition] (Pixel-Koordinaten im
  /// `world`-Raum der Kamera) abzubauen. Die eigentliche Abbau-Regel lebt
  /// bewusst in vt_world (Dart-Core), hier wird nur Pixel- auf
  /// Tile-Koordinaten umgerechnet und das Ergebnis gezählt.
  bool digAt(Vector2 worldPosition) {
    final tileX = (worldPosition.x / map.tileSize).floor();
    final tileY = (worldPosition.y / map.tileSize).floor();
    final mined = simulationWorld.mineTileAt(
      tileX,
      tileY,
      vt_world.ZLevel.surface,
    );
    if (mined == null) return false;
    minedResourceCount++;
    return true;
  }
}
