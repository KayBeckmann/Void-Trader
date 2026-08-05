import 'package:flutter_test/flutter_test.dart';
import 'package:vt_core/vt_core.dart';
import 'package:void_trader/game/void_trader_game.dart';
import 'package:void_trader/ui/game_ui_state.dart';
import 'package:void_trader/ui/tool_mode.dart';

void main() {
  group('GameUiState.from', () {
    test('spiegelt Inventar, Werkzeug und Feedback aus dem Spiel', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 5);
      game.activeTool.value = ToolMode.dig;
      game.feedbackMessage.value = 'Testmeldung';

      final state = GameUiState.from(game);

      expect(state.inventory[Resource.stone], 5);
      expect(state.activeTool, ToolMode.dig);
      expect(state.feedbackMessage, 'Testmeldung');
      expect(state.objectives, hasLength(5));
      expect(state.inspector.title, isNotEmpty);
    });

    test('Inventar-Snapshot ist unabhängig vom weiterlaufenden Spiel', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 1);

      final state = GameUiState.from(game);
      game.inventory.add(Resource.stone, 99);

      expect(state.inventory[Resource.stone], 1);
    });
  });
}
