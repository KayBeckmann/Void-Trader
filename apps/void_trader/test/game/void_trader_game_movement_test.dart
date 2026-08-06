import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
import 'package:vt_world/vt_world.dart' as vt_world;
import 'package:void_trader/game/void_trader_game.dart';

/// Roadmap-Sofort-Korrektur "Bewegung, Kollision, Startzone und Sicht/Fog
/// of War", Teil MOV-02: [VoidTraderGame] verdrahtet [PlayerComponent.
/// canMoveTo] gegen die vt_world-Kollisionsregel aus MOV-01.
void main() {
  group('VoidTraderGame Bewegungskollision', () {
    test('Wasser blockiert die Bewegung und setzt eine deutsche Meldung', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        1,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.water),
      );

      final startPosition = game.player.position.clone();
      game.player.velocity = Vector2(VoidTraderGame.tileSize, 0);
      game.player.update(1.0);

      expect(game.player.position, startPosition);
      expect(game.feedbackMessage.value, contains('Wasser'));
    });

    test('begehbares Tile lässt die Bewegung normal zu', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        1,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.grass),
      );

      final startPosition = game.player.position.clone();
      game.player.velocity = Vector2(VoidTraderGame.tileSize, 0);
      game.player.update(1.0);

      expect(game.player.position, isNot(startPosition));
    });

    test('ein platziertes Gebäude blockiert die Bewegung', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        1,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.grass),
      );
      game.inventory.add(Resource.stone, 3);
      final buildPosition = Vector2(1.5 * VoidTraderGame.tileSize, 0.5 * VoidTraderGame.tileSize);
      game.buildAt(buildPosition, BuildingType.wall);

      final startPosition = game.player.position.clone();
      game.player.velocity = Vector2(VoidTraderGame.tileSize, 0);
      game.player.update(1.0);

      expect(game.player.position, startPosition);
      expect(game.feedbackMessage.value, contains('Gebäude'));
    });

    test('an einer blockierten Achse entlanggleiten bleibt möglich', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      // Direkt östlich blockiert (Wasser), südlich weiterhin begehbare
      // Wiese (Startzone) — diagonale Bewegung sollte trotzdem in
      // y-Richtung vorankommen statt komplett zu stoppen.
      game.simulationWorld.setTileAt(
        1,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.water),
      );

      final startPosition = game.player.position.clone();
      game.player.velocity = Vector2(VoidTraderGame.tileSize, VoidTraderGame.tileSize);
      game.player.update(1.0);

      expect(game.player.position.x, startPosition.x);
      expect(game.player.position.y, isNot(startPosition.y));
    });
  });
}
