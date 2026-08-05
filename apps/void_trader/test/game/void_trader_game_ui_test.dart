import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
import 'package:vt_world/vt_world.dart' as vt_world;
import 'package:void_trader/game/void_trader_game.dart';
import 'package:void_trader/ui/tool_mode.dart';

void main() {
  group('VoidTraderGame.performActionAt', () {
    test('inspect-Modus löst keine Aktion aus', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        0,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.stone),
      );

      game.activeTool.value = ToolMode.inspect;
      game.performActionAt(Vector2.zero());

      expect(
        game.simulationWorld.tileAt(0, 0, vt_world.ZLevel.surface).type,
        vt_world.TileType.stone,
      );
    });

    test('dig-Modus baut das angeklickte Tile ab', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        0,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.stone),
      );

      game.activeTool.value = ToolMode.dig;
      game.performActionAt(Vector2.zero());

      expect(
        game.simulationWorld.tileAt(0, 0, vt_world.ZLevel.surface).type,
        vt_world.TileType.path,
      );
    });

    test('build-Modus ohne gewähltes Gebäude gibt Feedback statt zu bauen', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 10);

      game.activeTool.value = ToolMode.build;
      game.selectedBuildingType.value = null;
      game.performActionAt(game.player.position);

      expect(game.feedbackMessage.value, contains('Baumenü'));
      expect(
        game.simulationWorld.buildingAt(0, 0, vt_world.ZLevel.surface),
        isNull,
      );
    });

    test('build-Modus mit gewähltem Gebäude baut am Klickort', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 3);

      game.activeTool.value = ToolMode.build;
      game.selectedBuildingType.value = BuildingType.wall;
      game.performActionAt(game.player.position);

      final tileX = (game.player.position.x / VoidTraderGame.tileSize).floor();
      final tileY = (game.player.position.y / VoidTraderGame.tileSize).floor();
      expect(
        game.simulationWorld.buildingAt(tileX, tileY, vt_world.ZLevel.surface),
        BuildingType.wall,
      );
    });
  });

  group('VoidTraderGame.inspectTile', () {
    test('zeigt deutschen Tile-Namen ohne Gebäude', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        0,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.water),
      );

      final info = game.inspectTile(0, 0);

      expect(info.title, 'Wasser');
    });

    test('zeigt Craft-Aktion mit Sperrgrund an einer leeren Werkbank', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 2);
      game.inventory.add(Resource.ore, 1);
      game.buildAt(game.player.position, BuildingType.workbench);

      final tile = game.inspectedTile;
      final info = game.inspectTile(tile.x, tile.y);

      expect(info.title, 'Werkbank');
      expect(info.actions, hasLength(1));
      expect(info.actions.first.available, isFalse);
      expect(info.actions.first.blockedReason, contains('Rohstoffe'));
    });

    test('zeigt Bauvorschau im build-Modus mit gewähltem Gebäude', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        0,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.grass),
      );
      game.activeTool.value = ToolMode.build;
      game.selectedBuildingType.value = BuildingType.market;

      final info = game.inspectTile(0, 0);

      expect(info.actions.any((a) => a.label.contains('Marktkiosk')), isTrue);
    });
  });

  group('VoidTraderGame.inspectedTile', () {
    test('fällt ohne Auswahl auf die Spielerposition zurück', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      expect(game.selectedTile.value, isNull);
      expect(game.inspectedTile, (x: 0, y: 0));
    });

    test('nutzt selectedTile, sobald eines gesetzt ist', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      game.selectedTile.value = (x: 5, y: -2);

      expect(game.inspectedTile, (x: 5, y: -2));
    });
  });

  group('VoidTraderGame Ziel-Tracking', () {
    test('builtBuildingTypes/totalCrafted/cargoEverLoaded reagieren auf Erfolg', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 20);
      game.inventory.add(Resource.ore, 20);
      // Component direkt gutgeschrieben statt mehrfach zu craften — dieser
      // Test prüft das Fortschritts-Tracking, nicht die Rezept-Balance.
      game.inventory.add(Resource.component, 10);

      expect(game.builtBuildingTypes, isEmpty);
      expect(game.totalCrafted, 0);
      expect(game.cargoEverLoaded, isFalse);

      game.buildAt(game.player.position, BuildingType.workbench);
      expect(game.builtBuildingTypes, contains(BuildingType.workbench));

      game.craftAt(game.player.position);
      expect(game.totalCrafted, greaterThan(0));

      // Andere Tile-Position, da das Landepad nicht auf der bereits
      // gebauten Werkbank platziert werden kann (Tile schon belegt).
      final landingPadPosition = Vector2(5 * VoidTraderGame.tileSize, 5 * VoidTraderGame.tileSize);
      game.buildAt(landingPadPosition, BuildingType.landingPad);
      game.loadCargoAt(landingPadPosition);
      expect(game.cargoEverLoaded, isTrue);
    });
  });
}
