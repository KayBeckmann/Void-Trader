import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
import 'package:vt_physics/vt_physics.dart';
import 'package:vt_system/vt_system.dart';

import '../game/void_trader_game.dart';
import 'minimap_data.dart';
import 'objective.dart';
import 'tile_inspector_info.dart';
import 'tool_mode.dart';

/// Sichtradius der Minimap in Tiles (Roadmap HUD-13: "Renderbudget klein
/// halten") — bewusst GRÖSSER als der Kamera-/Fog-of-War-Sichtradius
/// ([VoidTraderGame._viewRadius] = 16): genau darin liegt der Sinn einer
/// Minimap, mehr von der bereits erkundeten Umgebung zu zeigen als gerade
/// auf dem Bildschirm sichtbar ist. `peekTileAt`/`ExplorationTracker`
/// bleiben trotzdem strikt auf bereits geladene/entdeckte Chunks
/// beschränkt (siehe [buildMinimapGrid]), das Budget wächst also nur bei
/// tatsächlich erkundeter Fläche, nicht bei frischer Chunk-Generierung.
const int _minimapRadiusTiles = 24;

/// Unveränderlicher Snapshot des UI-relevanten Spielzustands (Roadmap
/// UI-01). Wird periodisch aus [VoidTraderGame] gebaut, damit HUD-Widgets
/// nicht direkt an die Spiel-Engine gekoppelt sein müssen und sich mit
/// Beispielzustand ohne echtes Spiel testen lassen (siehe UI-02-Tests).
class GameUiState {
  final Map<Resource, int> inventory;
  final bool isDay;
  final String timeLabel;
  final Weather weather;
  final ToolMode activeTool;
  final BuildingType? selectedBuildingType;
  final TileInspectorInfo inspector;
  final String? feedbackMessage;
  final List<ObjectiveStatus> objectives;

  /// Aktuelle z-Ebene des Spielers (Roadmap MOV-03) — deutsches Label fürs
  /// HUD, siehe [VoidTraderGame.zLevelLabel].
  final String zLevelLabel;

  /// Credits separat vom übrigen Inventar (Roadmap HUD-11: TopStatusBar
  /// zeigt Credits prominent, nicht nur als Eintrag in der Ressourcenliste).
  final int credits;

  /// Summe aller Fracht-Einheiten im Schiffslager (Roadmap HUD-11:
  /// "Schiff/Fracht-Kurzstatus"), Credits UND Treibstoff ausgenommen —
  /// Credits liegen beim Spieler, nicht im Frachtraum (siehe
  /// VoidTraderGame.loadCargoAt); Treibstoff ist seit Roadmap Phase 9 V9
  /// kein Frachtgut, sondern der Antrieb des Schiffs (siehe [shipFuel]
  /// für dessen eigenen, separaten Stand).
  final int shipCargoCount;

  /// Kapazität des Laderaums (Roadmap Phase 9, V10: "Frachtraum-
  /// Kapazitätslimit") — fürs HUD als "belegt/Kapazität".
  final int shipCargoCapacity;

  /// Aktueller Treibstoffstand im Schiff (Roadmap Phase 9, V9:
  /// "Treibstoffverbrauch") — separat von [shipCargoCount], damit das HUD
  /// den Tankstand als eigene Größe zeigen kann statt ihn in der
  /// allgemeinen Fracht-Summe zu verstecken.
  final int shipFuel;

  /// Minimap-Raster um die Spielerposition (Roadmap HUD-13), Spieler ist
  /// per Konstruktion immer die Mitte — siehe [buildMinimapGrid].
  final List<List<MinimapCell>> minimapGrid;

  /// Blickrichtung des Spielers für den Minimap-Richtungspfeil (Roadmap
  /// FOW-02/HUD-13), als eigenständige Doubles statt Flame-Vector2 — die
  /// Widgets sollen nicht an die Flame-Typen gekoppelt sein.
  final double facingX;
  final double facingY;

  /// Ob die Systemkarte gerade als Vollbild-Overlay angezeigt wird
  /// (Roadmap Phase 9, V1-Slice "Systemkarte") und welches System sie
  /// zeigt — siehe [VoidTraderGame.showSystemMap]/[VoidTraderGame.
  /// currentSystem].
  final bool showSystemMap;
  final StarSystem system;

  /// An welchem Himmelskörper das Schiff gerade steht (Roadmap Phase 9,
  /// V2) — siehe [VoidTraderGame.shipLocationBodyId].
  final String shipLocationBodyId;

  const GameUiState({
    required this.inventory,
    required this.isDay,
    required this.timeLabel,
    required this.weather,
    required this.activeTool,
    required this.selectedBuildingType,
    required this.inspector,
    required this.feedbackMessage,
    required this.objectives,
    required this.zLevelLabel,
    required this.credits,
    required this.shipCargoCount,
    required this.shipCargoCapacity,
    required this.shipFuel,
    required this.minimapGrid,
    required this.facingX,
    required this.facingY,
    required this.showSystemMap,
    required this.system,
    required this.shipLocationBodyId,
  });

  factory GameUiState.from(VoidTraderGame game) {
    final tile = game.inspectedTile;
    final playerTile = (
      x: (game.player.position.x / VoidTraderGame.tileSize).floor(),
      y: (game.player.position.y / VoidTraderGame.tileSize).floor(),
    );
    return GameUiState(
      inventory: game.inventory.snapshot,
      isDay: game.dayNightCycle.isDay,
      timeLabel: _timeLabel(game.dayNightCycle),
      weather: game.weather.current,
      activeTool: game.activeTool.value,
      selectedBuildingType: game.selectedBuildingType.value,
      inspector: game.inspectTile(tile.x, tile.y),
      feedbackMessage: game.feedbackMessage.value,
      objectives: buildObjectives(
        stoneCount: game.inventory.count(Resource.stone),
        builtBuildingTypes: game.builtBuildingTypes,
        totalCrafted: game.totalCrafted,
        cargoEverLoaded: game.cargoEverLoaded,
      ),
      zLevelLabel: VoidTraderGame.zLevelLabel(game.currentZLevel.value),
      credits: game.inventory.count(Resource.credits),
      shipCargoCount: game.ship.cargoUsed,
      shipCargoCapacity: Ship.cargoCapacity,
      shipFuel: game.ship.cargo.count(Resource.fuel),
      minimapGrid: buildMinimapGrid(
        world: game.simulationWorld,
        explorationTracker: game.explorationTracker,
        centerX: playerTile.x,
        centerY: playerTile.y,
        z: game.currentZLevel.value,
        radiusTiles: _minimapRadiusTiles,
      ),
      facingX: game.player.facingDirection.x,
      facingY: game.player.facingDirection.y,
      showSystemMap: game.showSystemMap.value,
      system: game.currentSystem,
      shipLocationBodyId: game.shipLocationBodyId.value,
    );
  }

  static String _timeLabel(DayNightCycle cycle) {
    final totalMinutes = (cycle.timeOfDay * 24 * 60).floor();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
