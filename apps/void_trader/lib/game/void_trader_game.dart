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
/// Ein periodischer Fluid-Tick ([WorldFluidBridge]) lässt echtes Wasser aus
/// vt_world im sichtbaren Fenster fließen (Phase 3).
class VoidTraderGame extends FlameGame with HasKeyboardHandlerComponents {
  VoidTraderGame({int seed = 1}) : simulationWorld = vt_world.World(seed) {
    // In der Initializer-Liste kann fluidBridge noch nicht auf
    // simulationWorld verweisen (Felder dürfen sich dort nicht gegenseitig
    // referenzieren) — daher hier im Konstruktor-Body zugewiesen, wo
    // simulationWorld bereits gesetzt ist. Beide müssen zwingend dieselbe
    // World-Instanz teilen, sonst simuliert die Fluid-Brücke eine andere
    // Welt als die, in der der Spieler tatsächlich gräbt/läuft.
    fluidBridge = WorldFluidBridge(simulationWorld, vt_world.ZLevel.surface);
  }

  /// Radius des Debug-Fensters um den Weltursprung (in Tiles). Das Fenster
  /// ist damit `2 * _viewRadius` Tiles breit/hoch und zentriert auf (0,0) —
  /// dieselbe sichere Startzone, die vt_world garantiert.
  static const int _viewRadius = 16;

  /// Sekunden zwischen zwei Fluid-Simulationsschritten. Nicht jeden Frame,
  /// damit die Simulation chunk-basiert budgetiert bleibt (Roadmap
  /// Designregel Phase 3) statt jeden Tick das ganze Fenster neu zu bauen.
  static const double _fluidTickInterval = 0.5;

  final vt_world.World simulationWorld;
  late final WorldFluidBridge fluidBridge;
  late final DebugMapComponent map;
  late final PlayerComponent player;

  double _fluidTickAccumulator = 0;

  /// Zähler für erfolgreich abgebaute Tiles (Platzhalter fürs Inventar,
  /// echtes Ressourcensystem folgt in Phase 4).
  int minedResourceCount = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    const viewSize = _viewRadius * 2;

    map = DebugMapComponent(
      gameWorld: simulationWorld,
      originX: -_viewRadius,
      originY: -_viewRadius,
      tileWidth: viewSize,
      tileHeight: viewSize,
      z: vt_world.ZLevel.surface,
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

  @override
  void update(double dt) {
    super.update(dt);

    _fluidTickAccumulator += dt;
    if (_fluidTickAccumulator < _fluidTickInterval) return;
    _fluidTickAccumulator -= _fluidTickInterval;

    fluidBridge.step(
      originX: map.originX,
      originY: map.originY,
      width: map.tileWidth,
      height: map.tileHeight,
    );
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
