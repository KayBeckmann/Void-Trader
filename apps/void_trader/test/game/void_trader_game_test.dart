import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
import 'package:vt_world/vt_world.dart' as vt_world;
import 'package:void_trader/game/void_trader_game.dart';

void main() {
  group('VoidTraderGame Sprite-/Debug-Ansicht', () {
    test('onLoad erzeugt spriteMap als Standardansicht, Debug-Overlay ist aus', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      expect(game.spriteMap, isNotNull);
      expect(game.map.enabled, isFalse);
    });

    test('F1 schaltet das Debug-Overlay um', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      game.player.onAction?.call(LogicalKeyboardKey.f1, game.player.position);
      expect(game.map.enabled, isTrue);

      game.player.onAction?.call(LogicalKeyboardKey.f1, game.player.position);
      expect(game.map.enabled, isFalse);
    });
  });

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

  group('VoidTraderGame.sellAllAt', () {
    test('verkauft alle handelbaren Ressourcen an einem Marktkiosk', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 5 + 5); // Baukosten + zu verkaufen
      game.inventory.add(Resource.ore, 2 + 2); // Baukosten + zu verkaufen
      game.buildAt(game.player.position, BuildingType.market);

      final earned = game.sellAllAt(game.player.position);

      expect(earned, sellPrices[Resource.stone]! * 5 + sellPrices[Resource.ore]! * 2);
      expect(game.inventory.count(Resource.stone), 0);
      expect(game.inventory.count(Resource.ore), 0);
      expect(game.inventory.count(Resource.credits), earned);
    });

    test('liefert 0 ohne Marktkiosk an der Position', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 5);

      final earned = game.sellAllAt(game.player.position);

      expect(earned, 0);
      expect(game.inventory.count(Resource.stone), 5);
    });
  });

  group('VoidTraderGame.loadCargoAt', () {
    test('lädt Rohstoffe/Bauteile ins Schiff, Credits bleiben beim Spieler', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      final cost = buildingDefinitionFor(BuildingType.landingPad).buildCost;
      cost.forEach((resource, amount) => game.inventory.add(resource, amount));
      game.inventory.add(Resource.stone, 5); // zusätzlich zu verladen
      game.inventory.add(Resource.credits, 50);
      game.buildAt(game.player.position, BuildingType.landingPad);

      final loaded = game.loadCargoAt(game.player.position);

      expect(loaded, 5);
      expect(game.inventory.count(Resource.stone), 0);
      expect(game.ship.cargo.count(Resource.stone), 5);
      expect(game.inventory.count(Resource.credits), 50);
      expect(game.ship.cargo.count(Resource.credits), 0);
    });

    test('liefert 0 ohne Landepad an der Position', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 5);

      final loaded = game.loadCargoAt(game.player.position);

      expect(loaded, 0);
      expect(game.inventory.count(Resource.stone), 5);
      expect(game.ship.cargo.count(Resource.stone), 0);
    });
  });

  group('VoidTraderGame NPCs + Tag/Nacht-Zyklus', () {
    test('onLoad erzeugt mindestens 3 NPCs mit passenden Komponenten', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      expect(game.npcs.length, greaterThanOrEqualTo(3));
      expect(game.npcComponents.length, game.npcs.length);
      for (var i = 0; i < game.npcs.length; i++) {
        expect(game.npcComponents[i].npc, same(game.npcs[i]));
      }
    });

    test('update() lässt die Tageszeit voranschreiten', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      final before = game.dayNightCycle.timeOfDay;

      game.update(10);

      expect(game.dayNightCycle.timeOfDay, isNot(before));
    });

    test('update() tickt alle NPCs, ihre Bedürfnisse verändern sich', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      for (var i = 0; i < 20; i++) {
        game.update(1.0);
      }

      // Nach genug Zeit sollte sich mindestens ein Bedürfnis irgendeines
      // NPCs von seinem vollen Startwert entfernt haben.
      final anyChanged = game.npcs.any(
        (npc) =>
            npc.needs.hunger < 1.0 || npc.needs.thirst < 1.0 || npc.needs.tiredness < 1.0,
      );
      expect(anyChanged, isTrue);
    });
  });
}
