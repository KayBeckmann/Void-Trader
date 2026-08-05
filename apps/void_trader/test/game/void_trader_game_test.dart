import 'package:flutter_test/flutter_test.dart';
import 'package:vt_world/vt_world.dart' as vt_world;
import 'package:void_trader/game/void_trader_game.dart';

void main() {
  group('VoidTraderGame.digAt', () {
    test('baut ein Stein-Tile unter der übergebenen Position ab', () async {
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
      expect(
        game.simulationWorld.tileAt(tileX, tileY, vt_world.ZLevel.surface).type,
        vt_world.TileType.path,
      );
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
}
