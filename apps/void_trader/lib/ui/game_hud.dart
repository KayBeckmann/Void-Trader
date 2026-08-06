import 'package:flutter/material.dart';

import '../game/void_trader_game.dart';
import 'game_ui_state.dart';
import 'tool_mode.dart';
import 'widgets/build_menu.dart';
import 'widgets/feedback_toast.dart';
import 'widgets/hud_panel.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/objective_panel.dart';
import 'widgets/resource_bar.dart';
import 'widgets/toolbelt_panel.dart';
import 'widgets/top_status_bar.dart';

/// Flutter-HUD-Overlay für [VoidTraderGame] — komponiert aus eigenständigen
/// Panels (Roadmap UI-02) statt einer monolithischen Widget-Datei. Jedes
/// Panel bekommt reine Daten aus einem [GameUiState]-Snapshot, nicht die
/// [VoidTraderGame]-Instanz selbst — das macht die Panels ohne echtes Spiel
/// mit Beispielzustand testbar (siehe test/ui/widgets/).
///
/// Nur die reinen Info-Panels (Topbar/Ressourcen/Inspector/Feedback/Ziele)
/// stecken in [IgnorePointer] — [ToolbeltPanel] und [BuildMenu] brauchen
/// echten Touch-Input, um Klicks in Modus-/Gebäudeauswahl zu übersetzen
/// (Roadmap UI-04/UI-05). [BuildMenu] erscheint nur, während [ToolMode.
/// build] aktiv ist.
class GameHud extends StatelessWidget {
  final VoidTraderGame game;

  const GameHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        game.hudTick,
        game.activeTool,
        game.selectedBuildingType,
        game.selectedTile,
        game.feedbackMessage,
        game.currentZLevel,
      ]),
      builder: (context, _) {
        final state = GameUiState.from(game);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TopStatusBar(
                            isDay: state.isDay,
                            timeLabel: state.timeLabel,
                            weather: state.weather,
                            zLevelLabel: state.zLevelLabel,
                          ),
                          const SizedBox(height: 6),
                          ResourceBar(inventory: state.inventory),
                        ],
                      ),
                      ObjectivePanel(objectives: state.objectives),
                    ],
                  ),
                ),
                const Spacer(),
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InspectorPanel(info: state.inspector),
                      const SizedBox(height: 6),
                      FeedbackToast(message: state.feedbackMessage),
                      const SizedBox(height: 6),
                      const _ControlsLegend(),
                    ],
                  ),
                ),
                if (state.activeTool == ToolMode.build) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BuildMenu(
                      selected: state.selectedBuildingType,
                      inventory: state.inventory,
                      onSelect: (type) => game.selectedBuildingType.value = type,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Align(
                  child: ToolbeltPanel(
                    activeTool: state.activeTool,
                    onSelect: (mode) => game.activeTool.value = mode,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControlsLegend extends StatelessWidget {
  const _ControlsLegend();

  @override
  Widget build(BuildContext context) {
    return const HudPanel(
      color: Color(0x80000000),
      child: Text(
        'WASD/Pfeile Bewegen · Werkzeug per Klick oder Taste wählen · '
        'Klick auf die Karte wirkt am Zieltile · F1 Debug-Ansicht',
        style: TextStyle(color: Colors.white70, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}
