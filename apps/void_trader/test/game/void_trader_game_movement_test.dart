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

  group('VoidTraderGame z-Achsen-Wechsel über Rampen (Roadmap MOV-03)', () {
    test('Betreten einer Rampe wechselt von Oberfläche zu Hügeln', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        1,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.slope),
      );

      expect(game.currentZLevel.value, vt_world.ZLevel.surface);

      game.player.position = Vector2(1.5 * VoidTraderGame.tileSize, 0.5 * VoidTraderGame.tileSize);
      game.update(0.01);

      expect(game.currentZLevel.value, vt_world.ZLevel.hills);
      expect(game.feedbackMessage.value, contains('Hügel'));
    });

    test('erneutes Betreten derselben Rampe von den Hügeln aus wechselt zurück', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        1,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.slope),
      );
      game.simulationWorld.setTileAt(
        1,
        0,
        vt_world.ZLevel.hills,
        const vt_world.Tile(vt_world.TileType.slope),
      );
      game.simulationWorld.setTileAt(
        2,
        0,
        vt_world.ZLevel.hills,
        const vt_world.Tile(vt_world.TileType.dirt),
      );

      game.player.position = Vector2(1.5 * VoidTraderGame.tileSize, 0.5 * VoidTraderGame.tileSize);
      game.update(0.01);
      expect(game.currentZLevel.value, vt_world.ZLevel.hills);

      // Rampen-Tile verlassen — kein erneuter Wechsel auf einem normalen
      // Hügel-Tile.
      game.player.position = Vector2(2.5 * VoidTraderGame.tileSize, 0.5 * VoidTraderGame.tileSize);
      game.update(0.01);
      expect(game.currentZLevel.value, vt_world.ZLevel.hills);

      // Rampen-Tile erneut betreten -> zurück zur Oberfläche.
      game.player.position = Vector2(1.5 * VoidTraderGame.tileSize, 0.5 * VoidTraderGame.tileSize);
      game.update(0.01);
      expect(game.currentZLevel.value, vt_world.ZLevel.surface);
      expect(game.feedbackMessage.value, contains('Oberfläche'));
    });

    test('Stehenbleiben auf einer Rampe löst keinen wiederholten Wechsel aus', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        1,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.slope),
      );

      game.player.position = Vector2(1.5 * VoidTraderGame.tileSize, 0.5 * VoidTraderGame.tileSize);
      game.update(0.01);
      expect(game.currentZLevel.value, vt_world.ZLevel.hills);

      game.update(0.01);
      game.update(0.01);
      expect(game.currentZLevel.value, vt_world.ZLevel.hills);
    });
  });

  group('VoidTraderGame.zLevelLabel', () {
    test('liefert deutsche Bezeichnungen je Ebene', () {
      expect(VoidTraderGame.zLevelLabel(vt_world.ZLevel.surface), 'Oberfläche');
      expect(VoidTraderGame.zLevelLabel(vt_world.ZLevel.hills), 'Hügel');
      expect(VoidTraderGame.zLevelLabel(vt_world.ZLevel.mountains), 'Berge');
      expect(VoidTraderGame.zLevelLabel(vt_world.ZLevel.cellar), 'Keller');
    });
  });

  group('VoidTraderGame Fog of War (Roadmap FOW-04)', () {
    test('onLoad() berechnet das Sichtfeld sofort, kein leerer erster Frame', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      final tile = (
        x: (game.player.position.x / VoidTraderGame.tileSize).floor(),
        y: (game.player.position.y / VoidTraderGame.tileSize).floor(),
      );
      expect(game.explorationTracker.stateAt(tile.x, tile.y), vt_world.VisibilityState.visible);
    });

    test('update() aktualisiert das Sichtfeld periodisch, wenn sich der Spieler bewegt', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      game.player.position = Vector2(20 * VoidTraderGame.tileSize, 20 * VoidTraderGame.tileSize);
      // Über den Visibility-Tick-Intervall hinaus simulieren.
      game.update(0.2);

      expect(game.explorationTracker.stateAt(20, 20), vt_world.VisibilityState.visible);
    });

    test('einmal entdeckte Tiles bleiben seenButNotVisible, wenn der Spieler weiterzieht', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.update(0.2);

      final startTile = (
        x: (game.player.position.x / VoidTraderGame.tileSize).floor(),
        y: (game.player.position.y / VoidTraderGame.tileSize).floor(),
      );

      game.player.position = Vector2(40 * VoidTraderGame.tileSize, 40 * VoidTraderGame.tileSize);
      game.update(0.2);

      expect(
        game.explorationTracker.stateAt(startTile.x, startTile.y),
        vt_world.VisibilityState.seenButNotVisible,
      );
    });
  });
}
