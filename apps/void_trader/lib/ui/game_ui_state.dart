import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
import 'package:vt_physics/vt_physics.dart';

import '../game/void_trader_game.dart';
import 'objective.dart';
import 'tile_inspector_info.dart';
import 'tool_mode.dart';

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
  });

  factory GameUiState.from(VoidTraderGame game) {
    final tile = game.inspectedTile;
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
    );
  }

  static String _timeLabel(DayNightCycle cycle) {
    final totalMinutes = (cycle.timeOfDay * 24 * 60).floor();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
