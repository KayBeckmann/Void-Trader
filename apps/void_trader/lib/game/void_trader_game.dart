import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
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
/// steuerbare [PlayerComponent] mit Kamera-Follow. Interaktionen: Graben/
/// Abbauen (Space/E, Phase 1), Bauen (1 = Mauer, 2 = Werkbank) und Craften
/// (C an einer Werkbank) — Phase 4. Ein periodischer Fluid-Tick
/// ([WorldFluidBridge]) lässt echtes Wasser aus vt_world im sichtbaren
/// Fenster fließen (Phase 3).
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
  final Inventory inventory = Inventory();
  late final WorldFluidBridge fluidBridge;
  late final DebugMapComponent map;
  late final PlayerComponent player;

  double _fluidTickAccumulator = 0;

  /// Zähler für erfolgreich abgebaute Tiles (nützlich für UI/Debug,
  /// unabhängig vom Inventarstand).
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
    player = PlayerComponent(position: map.size / 2, onAction: _handleAction);

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

  /// Ordnet Tastendrücke den Interaktionen zu. Lebt bewusst im Spiel statt
  /// in [PlayerComponent], damit die Steuerung unabhängig von den
  /// konkreten Interaktionen testbar bleibt.
  void _handleAction(LogicalKeyboardKey key, Vector2 position) {
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyE) {
      digAt(position);
    } else if (key == LogicalKeyboardKey.digit1) {
      buildAt(position, BuildingType.wall);
    } else if (key == LogicalKeyboardKey.digit2) {
      buildAt(position, BuildingType.workbench);
    } else if (key == LogicalKeyboardKey.keyC) {
      craftAt(position);
    }
  }

  /// Versucht, das Tile unter [worldPosition] (Pixel-Koordinaten im
  /// `world`-Raum der Kamera) abzubauen. Die eigentliche Abbau-Regel lebt
  /// bewusst in vt_world (Dart-Core), hier wird nur Pixel- auf
  /// Welt-Tile-Koordinaten umgerechnet, das Ergebnis gezählt und passende
  /// Rohstoffe ins Inventar gelegt.
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
    final resource = _resourceForMinedTile(mined);
    if (resource != null) inventory.add(resource, 1);
    return true;
  }

  /// Versucht, [type] unter [worldPosition] zu platzieren — nur wenn die
  /// Baukosten im Inventar vorhanden sind und vt_world die Platzierung
  /// erlaubt (begehbares, unbelegtes Tile). Zieht die Kosten erst nach
  /// erfolgreicher Platzierung ab.
  bool buildAt(Vector2 worldPosition, BuildingType type) {
    final tileX = map.originX + (worldPosition.x / map.tileSize).floor();
    final tileY = map.originY + (worldPosition.y / map.tileSize).floor();
    final cost = buildingDefinitionFor(type).buildCost;
    if (!inventory.hasAll(cost)) return false;

    final placed = simulationWorld.placeBuildingAt(
      tileX,
      tileY,
      vt_world.ZLevel.surface,
      type,
    );
    if (!placed) return false;

    inventory.removeAll(cost);
    return true;
  }

  /// Craftet [basicComponentRecipe], falls unter [worldPosition] eine
  /// Werkbank steht und genug Rohstoffe vorhanden sind — die erste
  /// vollständige "Sammeln → Verarbeiten"-Stufe der Produktionskette.
  bool craftAt(Vector2 worldPosition) {
    final tileX = map.originX + (worldPosition.x / map.tileSize).floor();
    final tileY = map.originY + (worldPosition.y / map.tileSize).floor();
    final building = simulationWorld.buildingAt(tileX, tileY, vt_world.ZLevel.surface);
    if (building != BuildingType.workbench) return false;
    if (!inventory.hasAll(basicComponentRecipe.input)) return false;

    inventory.craft(
      basicComponentRecipe.input,
      basicComponentRecipe.output,
      outputAmount: basicComponentRecipe.outputAmount,
    );
    return true;
  }

  /// Welcher Rohstoff (falls überhaupt einer) beim Abbau von [type] anfällt.
  /// Fels aus Bergen (`stone`) und Höhlenwänden (`rockWall`) liefert
  /// dasselbe Material, nur Erzadern liefern `ore`.
  Resource? _resourceForMinedTile(vt_world.TileType type) {
    switch (type) {
      case vt_world.TileType.stone:
      case vt_world.TileType.rockWall:
        return Resource.stone;
      case vt_world.TileType.ore:
        return Resource.ore;
      default:
        return null;
    }
  }
}
