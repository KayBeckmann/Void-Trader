import 'package:flutter_test/flutter_test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
import 'package:vt_world/vt_world.dart' as vt_world;
import 'package:void_trader/game/void_trader_game.dart';

void main() {
  group('VoidTraderGame.digAt', () {
    test('baut ein Stein-Tile ab und legt Stein ins Inventar', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      final tileX = game.map.originX + (game.player.position.x / game.map.tileSize).floor();
      final tileY = game.map.originY + (game.player.position.y / game.map.tileSize).floor();
      game.simulationWorld.setTileAt(
        tileX,
        tileY,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.stone),
      );

      final success = game.digAt(game.player.position);

      expect(success, isTrue);
      expect(game.minedResourceCount, 1);
      expect(game.inventory.count(Resource.stone), 1);
      expect(
        game.simulationWorld.tileAt(tileX, tileY, vt_world.ZLevel.surface).type,
        vt_world.TileType.path,
      );
    });

    test('baut Erz ab und legt Erz statt Stein ins Inventar', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      final tileX = game.map.originX + (game.player.position.x / game.map.tileSize).floor();
      final tileY = game.map.originY + (game.player.position.y / game.map.tileSize).floor();
      game.simulationWorld.setTileAt(
        tileX,
        tileY,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.ore),
      );

      game.digAt(game.player.position);

      expect(game.inventory.count(Resource.ore), 1);
      expect(game.inventory.count(Resource.stone), 0);
    });

    test('liefert false für nicht abbaubare Tiles und zählt nichts', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      final tileX = game.map.originX + (game.player.position.x / game.map.tileSize).floor();
      final tileY = game.map.originY + (game.player.position.y / game.map.tileSize).floor();
      game.simulationWorld.setTileAt(
        tileX,
        tileY,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.grass),
      );

      final success = game.digAt(game.player.position);

      expect(success, isFalse);
      expect(game.minedResourceCount, 0);
    });
  });

  group('VoidTraderGame Fluid-Tick', () {
    test('update() lässt Wasser über die Zeit ins Nachbar-Tile fließen', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      const z = vt_world.ZLevel.surface;
      game.simulationWorld.setTileAt(
        0,
        0,
        z,
        const vt_world.Tile(vt_world.TileType.water, waterLevel: 1.0),
      );
      game.simulationWorld.setTileAt(1, 0, z, const vt_world.Tile(vt_world.TileType.path));

      // Genug Zeit für mehrere Fluid-Ticks (Intervall 0.5s) simulieren.
      for (var i = 0; i < 10; i++) {
        game.update(0.5);
      }

      expect(game.simulationWorld.tileAt(1, 0, z).waterLevel, greaterThan(0));
    });

    test('update() unterhalb des Tick-Intervalls simuliert noch nichts', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      const z = vt_world.ZLevel.surface;
      game.simulationWorld.setTileAt(
        0,
        0,
        z,
        const vt_world.Tile(vt_world.TileType.water, waterLevel: 1.0),
      );
      game.simulationWorld.setTileAt(1, 0, z, const vt_world.Tile(vt_world.TileType.path));

      game.update(0.1);

      expect(game.simulationWorld.tileAt(1, 0, z).waterLevel, 0);
    });
  });

  group('VoidTraderGame.buildAt', () {
    test('platziert nur mit ausreichend Rohstoffen und zieht Kosten ab', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      final failedWithoutResources = game.buildAt(game.player.position, BuildingType.wall);
      expect(failedWithoutResources, isFalse);

      game.inventory.add(Resource.stone, 3);
      final success = game.buildAt(game.player.position, BuildingType.wall);

      expect(success, isTrue);
      expect(game.inventory.count(Resource.stone), 0);

      final tileX = game.map.originX + (game.player.position.x / game.map.tileSize).floor();
      final tileY = game.map.originY + (game.player.position.y / game.map.tileSize).floor();
      expect(
        game.simulationWorld.buildingAt(tileX, tileY, vt_world.ZLevel.surface),
        BuildingType.wall,
      );
    });

    test('scheitert auf bereits belegtem Tile, ohne Kosten abzuziehen', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 10);

      game.buildAt(game.player.position, BuildingType.wall);
      final stoneAfterFirst = game.inventory.count(Resource.stone);
      final second = game.buildAt(game.player.position, BuildingType.wall);

      expect(second, isFalse);
      expect(game.inventory.count(Resource.stone), stoneAfterFirst);
    });
  });

  group('VoidTraderGame.craftAt', () {
    test('craftet nur an einer Werkbank mit genug Rohstoffen', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 10);
      game.inventory.add(Resource.ore, 10);

      final withoutWorkbench = game.craftAt(game.player.position);
      expect(withoutWorkbench, isFalse);

      game.buildAt(game.player.position, BuildingType.workbench);
      final success = game.craftAt(game.player.position);

      expect(success, isTrue);
      expect(game.inventory.count(Resource.component), 1);
    });

    test('scheitert ohne genug Rohstoffe, auch an einer Werkbank', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      // Reicht exakt für den Bau der Werkbank, danach ist nichts mehr übrig.
      game.inventory.add(Resource.stone, 2);
      game.inventory.add(Resource.ore, 1);
      game.buildAt(game.player.position, BuildingType.workbench);

      final success = game.craftAt(game.player.position);

      expect(success, isFalse);
      expect(game.inventory.count(Resource.component), 0);
    });
  });
}
