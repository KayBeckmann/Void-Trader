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
/// Zeigt die [DebugMapComponent] (Tiles + Wasserzustand rund um den
/// Weltursprung, dort liegt die sichere Startzone aus vt_world) plus eine
/// steuerbare [PlayerComponent] mit Kamera-Follow und einem ersten
/// Interaktionswerkzeug (Graben/Abbauen) — Phase 1/2 der Reboot-Roadmap.
class VoidTraderGame extends FlameGame with HasKeyboardHandlerComponents {
  VoidTraderGame({int seed = 1}) : simulationWorld = vt_world.World(seed);

  /// Radius des Debug-Fensters um den Weltursprung (in Tiles). Das Fenster
  /// ist damit `2 * _viewRadius` Tiles breit/hoch und zentriert auf (0,0) —
  /// dieselbe sichere Startzone, die vt_world garantiert.
  static const int _viewRadius = 16;

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

    const viewSize = _viewRadius * 2;
    debugFluidGrid = FluidGrid(viewSize, viewSize);
    // Demo-Wasserquelle für den Debug-Screen. Phase 3 koppelt das Fluid-Grid
    // an echte Gelände-Höhen aus vt_world statt an ein leeres Demo-Grid.
    debugFluidGrid.addWater(_viewRadius + 6, _viewRadius + 6, 6);

    map = DebugMapComponent(
      gameWorld: simulationWorld,
      originX: -_viewRadius,
      originY: -_viewRadius,
      tileWidth: viewSize,
      tileHeight: viewSize,
      z: vt_world.ZLevel.surface,
      fluidGrid: debugFluidGrid,
    );

    // map.size / 2 entspricht damit exakt Welt-Tile (0,0) — Mitte der
    // sicheren Startzone.
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
  /// Welt-Tile-Koordinaten umgerechnet und das Ergebnis gezählt.
  bool digAt(Vector2 worldPosition) {
    final tileX = map.originX + (worldPosition.x / map.tileSize).floor();
    final tileY = map.originY + (worldPosition.y / map.tileSize).floor();
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
