import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
import 'package:vt_drones/vt_drones.dart';
import 'package:vt_system/vt_system.dart';
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

    test('Interaktionen funktionieren auch weit entfernt vom Weltursprung', () async {
      // Die Karte war früher an ein festes Fenster um (0,0) gebunden —
      // dieser Test würde fehlschlagen, wenn diese Kopplung zurückkäme.
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      game.player.position = Vector2(500 * VoidTraderGame.tileSize, -300 * VoidTraderGame.tileSize);
      game.simulationWorld.setTileAt(
        500,
        -300,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.stone),
      );

      final success = game.digAt(game.player.position);

      expect(success, isTrue);
      expect(
        game.simulationWorld.tileAt(500, -300, vt_world.ZLevel.surface).type,
        vt_world.TileType.path,
      );
    });
  });

  group('VoidTraderGame Systemkarte (Roadmap Phase 9)', () {
    test('ist standardmäßig geschlossen und zeigt das Standard-Heimatsystem', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      expect(game.showSystemMap.value, isFalse);
      expect(game.currentSystem.name, isNotEmpty);
      expect(game.currentSystem.bodies, isNotEmpty);
    });

    test('Taste M schaltet die Systemkarte um', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      game.player.onAction?.call(LogicalKeyboardKey.keyM, game.player.position);
      expect(game.showSystemMap.value, isTrue);

      game.player.onAction?.call(LogicalKeyboardKey.keyM, game.player.position);
      expect(game.showSystemMap.value, isFalse);
    });

    test('Schiff startet am Heimatplaneten', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      expect(game.shipLocationBodyId.value, game.currentSystem.homePlanet.id);
    });

    test('travelTo wechselt den Schiffsstandort zu einem existierenden Körper', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      final destination = game.currentSystem.bodies.firstWhere(
        (body) => body.id != game.currentSystem.homePlanet.id,
      );

      final success = game.travelTo(destination.id);

      expect(success, isTrue);
      expect(game.shipLocationBodyId.value, destination.id);
      expect(game.feedbackMessage.value, contains(destination.name));
    });

    test('travelTo scheitert für eine unbekannte Körper-id', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      final before = game.shipLocationBodyId.value;

      final success = game.travelTo('kein-echter-koerper');

      expect(success, isFalse);
      expect(game.shipLocationBodyId.value, before);
    });

    test('travelTo zum aktuellen Standort ist ein No-op', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      final currentId = game.shipLocationBodyId.value;

      final success = game.travelTo(currentId);

      expect(success, isFalse);
      expect(game.shipLocationBodyId.value, currentId);
    });

    test('travelTo lässt die Spielzeit um die Reisedauer voranschreiten (Roadmap V6)', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      final before = game.dayNightCycle.dayNumber + game.dayNightCycle.timeOfDay;
      final destination = game.currentSystem.bodies.firstWhere(
        (body) => body.id != game.currentSystem.homePlanet.id,
      );

      game.travelTo(destination.id);

      final after = game.dayNightCycle.dayNumber + game.dayNightCycle.timeOfDay;
      expect(after, greaterThan(before));
    });

    test('eine weitere Reise kostet mehr Spielzeit als eine nahe (Roadmap V6)', () async {
      // Zwei getrennte Spiele, damit sich die Reisen nicht gegenseitig
      // beeinflussen (beide starten identisch am Heimatplaneten).
      final gameNear = VoidTraderGame(seed: 1);
      await gameNear.onLoad();
      final near = gameNear.currentSystem.bodies.firstWhere(
        (body) => body.type == CelestialBodyType.station && body.priceMultiplier == 1.0,
      );
      final beforeNear = gameNear.dayNightCycle.dayNumber + gameNear.dayNightCycle.timeOfDay;
      gameNear.travelTo(near.id);
      final elapsedNear =
          (gameNear.dayNightCycle.dayNumber + gameNear.dayNightCycle.timeOfDay) - beforeNear;

      final gameFar = VoidTraderGame(seed: 1);
      await gameFar.onLoad();
      final far = gameFar.currentSystem.bodies.firstWhere(
        (body) => body.type == CelestialBodyType.station && body.priceMultiplier != 1.0,
      );
      final beforeFar = gameFar.dayNightCycle.dayNumber + gameFar.dayNightCycle.timeOfDay;
      gameFar.travelTo(far.id);
      final elapsedFar =
          (gameFar.dayNightCycle.dayNumber + gameFar.dayNightCycle.timeOfDay) - beforeFar;

      expect(elapsedFar, greaterThan(elapsedNear));
    });

    test('eine fehlgeschlagene Reise kostet keine Spielzeit', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      final before = game.dayNightCycle.dayNumber + game.dayNightCycle.timeOfDay;

      game.travelTo('kein-echter-koerper');

      final after = game.dayNightCycle.dayNumber + game.dayNightCycle.timeOfDay;
      expect(after, before);
    });

    test('sellDockedShipCargo scheitert ohne Andocken an einer Station', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.ship.cargo.add(Resource.stone, 5);

      final earned = game.sellDockedShipCargo();

      expect(earned, 0);
      expect(game.feedbackMessage.value, contains('keine Handelsstation'));
      expect(game.ship.cargo.count(Resource.stone), 5);
    });

    test('sellDockedShipCargo verkauft die Fracht an einer Handelsstation für Credits', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.ship.cargo.add(Resource.stone, 5);
      game.ship.cargo.add(Resource.ore, 2);
      final station = game.currentSystem.bodies.firstWhere(
        (body) => body.type == CelestialBodyType.station,
      );
      game.travelTo(station.id);
      final creditsBefore = game.inventory.count(Resource.credits);

      final earned = game.sellDockedShipCargo();

      expect(earned, greaterThan(0));
      expect(game.inventory.count(Resource.credits), creditsBefore + earned);
      expect(game.ship.cargo.count(Resource.stone), 0);
      expect(game.ship.cargo.count(Resource.ore), 0);
      expect(game.feedbackMessage.value, contains('Fracht verkauft'));
    });

    test('sellDockedShipCargo nutzt die Stationspreise, nicht die Planet-Marktpreise', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.ship.cargo.add(Resource.stone, 4);
      final station = game.currentSystem.bodies.firstWhere(
        (body) => body.type == CelestialBodyType.station,
      );
      game.travelTo(station.id);

      final earned = game.sellDockedShipCargo();

      expect(earned, 4 * stationSellPrices[Resource.stone]!);
      expect(earned, isNot(4 * sellPrices[Resource.stone]!));
    });

    test('sellDockedShipCargo skaliert mit dem Preisniveau der Station (Roadmap V5)', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.ship.cargo.add(Resource.stone, 4);
      final outpost = game.currentSystem.bodies.firstWhere(
        (body) => body.type == CelestialBodyType.station && body.priceMultiplier != 1.0,
      );
      game.travelTo(outpost.id);

      final earned = game.sellDockedShipCargo();

      expect(
        earned,
        (4 * stationSellPrices[Resource.stone]! * outpost.priceMultiplier).round(),
      );
      expect(earned, greaterThan(4 * stationSellPrices[Resource.stone]!));
    });

    test('sellDockedShipCargo meldet leere Fracht statt eines Fehlers', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      final station = game.currentSystem.bodies.firstWhere(
        (body) => body.type == CelestialBodyType.station,
      );
      game.travelTo(station.id);

      final earned = game.sellDockedShipCargo();

      expect(earned, 0);
      expect(game.feedbackMessage.value, contains('Keine verkäufliche Fracht'));
    });
  });

  group('VoidTraderGame.digAt', () {
    test('baut ein Stein-Tile ab und legt Stein ins Inventar', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      final tileX = (game.player.position.x / VoidTraderGame.tileSize).floor();
      final tileY = (game.player.position.y / VoidTraderGame.tileSize).floor();
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

      final tileX = (game.player.position.x / VoidTraderGame.tileSize).floor();
      final tileY = (game.player.position.y / VoidTraderGame.tileSize).floor();
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

      final tileX = (game.player.position.x / VoidTraderGame.tileSize).floor();
      final tileY = (game.player.position.y / VoidTraderGame.tileSize).floor();
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

  group('VoidTraderGame.sealAt (Roadmap MVP: "Graben/Pumpe/Abdichten")', () {
    test('dichtet ein geflutetes Tile sofort vollständig ab', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      final tileX = (game.player.position.x / VoidTraderGame.tileSize).floor();
      final tileY = (game.player.position.y / VoidTraderGame.tileSize).floor();
      game.simulationWorld.setTileAt(
        tileX,
        tileY,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.path, waterLevel: 0.7),
      );

      final success = game.sealAt(game.player.position);

      expect(success, isTrue);
      expect(game.feedbackMessage.value, 'Abgedichtet.');
      expect(
        game.simulationWorld.tileAt(tileX, tileY, vt_world.ZLevel.surface).waterLevel,
        0,
      );
    });

    test('liefert false auf einem trockenen Tile', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      final success = game.sealAt(game.player.position);

      expect(success, isFalse);
      expect(game.feedbackMessage.value, 'Hier steht kein Wasser.');
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

      final tileX = (game.player.position.x / VoidTraderGame.tileSize).floor();
      final tileY = (game.player.position.y / VoidTraderGame.tileSize).floor();
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

    test('Minendrohne scheitert ohne abbaubares Nachbar-Tile (Roadmap Phase 8)', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 20);
      game.inventory.add(Resource.ore, 20);
      game.inventory.add(Resource.component, 20);

      // Spawn-Sicherheitszone ist immer Wiese — garantiert kein
      // abbaubares Nachbar-Tile.
      final success = game.buildAt(game.player.position, BuildingType.miningDrone);

      expect(success, isFalse);
      expect(game.feedbackMessage.value, contains('keine abbaubare Ressource'));
      expect(game.inventory.count(Resource.stone), 20); // Kosten nicht abgezogen
    });

    test('Minendrohne wird mit abbaubarem Nachbar-Tile platziert', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 20);
      game.inventory.add(Resource.ore, 20);
      game.inventory.add(Resource.component, 20);

      final buildPosition = Vector2(3 * VoidTraderGame.tileSize, 3 * VoidTraderGame.tileSize);
      game.simulationWorld.setTileAt(
        4,
        3,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.stone),
      );

      final success = game.buildAt(buildPosition, BuildingType.miningDrone);

      expect(success, isTrue);
      expect(
        game.simulationWorld.buildingAt(3, 3, vt_world.ZLevel.surface),
        BuildingType.miningDrone,
      );
    });

    test('Pumpe scheitert ohne geflutetes Nachbar-Tile (Roadmap MVP)', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 20);
      game.inventory.add(Resource.component, 20);

      // Spawn-Sicherheitszone ist immer trockene Wiese — garantiert kein
      // geflutetes Nachbar-Tile.
      final success = game.buildAt(game.player.position, BuildingType.pump);

      expect(success, isFalse);
      expect(game.feedbackMessage.value, contains('keine Überflutung'));
      expect(game.inventory.count(Resource.stone), 20); // Kosten nicht abgezogen
    });

    test('Pumpe wird mit geflutetem Nachbar-Tile platziert', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 20);
      game.inventory.add(Resource.component, 20);

      final buildPosition = Vector2(3 * VoidTraderGame.tileSize, 3 * VoidTraderGame.tileSize);
      game.simulationWorld.setTileAt(
        4,
        3,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.path, waterLevel: 0.5),
      );

      final success = game.buildAt(buildPosition, BuildingType.pump);

      expect(success, isTrue);
      expect(
        game.simulationWorld.buildingAt(3, 3, vt_world.ZLevel.surface),
        BuildingType.pump,
      );
    });
  });

  group('VoidTraderGame Pumpen-Tick (Roadmap MVP: "Graben/Pumpe/Abdichten")', () {
    // Baut weit entfernt vom Weltursprung (analog zum Test "Interaktionen
    // funktionieren auch weit entfernt vom Weltursprung" oben) — der
    // Fluid-Tick simuliert nur ein Fenster um die (unbewegte) Spielerfigur
    // bei Spawn, damit bleibt das echte, prozedural generierte Gewässer
    // in der Seed-1-Welt außen vor und beeinflusst diese Tests nicht.
    Future<VoidTraderGame> buildGameWithOneFloodedNeighbor({double waterLevel = 0.5}) async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 20);
      game.inventory.add(Resource.component, 20);
      final buildPosition = Vector2(500 * VoidTraderGame.tileSize, 300 * VoidTraderGame.tileSize);
      // Anders als bei der Minendrohne (immer in der garantiert begehbaren
      // Spawn-Sicherheitszone getestet) liegt dieser Standort weit weg vom
      // Ursprung — die eigentliche Bau-Kachel muss daher explizit begehbar
      // gemacht werden, statt sich auf echte prozedurale Generierung zu
      // verlassen.
      game.simulationWorld.setTileAt(
        500,
        300,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.grass),
      );
      game.simulationWorld.setTileAt(
        501,
        300,
        vt_world.ZLevel.surface,
        vt_world.Tile(vt_world.TileType.path, waterLevel: waterLevel),
      );
      final built = game.buildAt(buildPosition, BuildingType.pump);
      assert(built, 'Testvoraussetzung: Pumpe muss sich hier platzieren lassen');
      return game;
    }

    test('pumpt über mehrere Ticks Wasser aus dem Nachbar-Tile ab', () async {
      final game = await buildGameWithOneFloodedNeighbor(waterLevel: 0.5);

      game.update(1.0);

      final afterOneTick = game.simulationWorld
          .tileAt(501, 300, vt_world.ZLevel.surface)
          .waterLevel;
      expect(afterOneTick, lessThan(0.5));
      expect(afterOneTick, greaterThan(0));
    });

    test('legt ein Nachbar-Tile über genug Ticks vollständig trocken', () async {
      final game = await buildGameWithOneFloodedNeighbor(waterLevel: 0.3);

      // 0.3 / 0.15 pro Tick = 2 Ticks bis vollständig trocken.
      for (var i = 0; i < 5; i++) {
        game.update(1.0);
      }

      expect(game.simulationWorld.tileAt(501, 300, vt_world.ZLevel.surface).waterLevel, 0);
      expect(
        game.simulationWorld.buildingAt(500, 300, vt_world.ZLevel.surface),
        BuildingType.pump,
      );
    });

    test('bleibt untätig stehen, ohne Fehler, wenn kein Wasser mehr in Reichweite ist', () async {
      final game = await buildGameWithOneFloodedNeighbor(waterLevel: 0.1);

      for (var i = 0; i < 10; i++) {
        game.update(1.0);
      }

      expect(game.simulationWorld.tileAt(501, 300, vt_world.ZLevel.surface).waterLevel, 0);
      expect(
        game.simulationWorld.buildingAt(500, 300, vt_world.ZLevel.surface),
        BuildingType.pump,
      );
    });

    test('Inspector zeigt aktiven Pump-Status mit gefluteter Nachbarschaft', () async {
      final game = await buildGameWithOneFloodedNeighbor();

      final info = game.inspectTile(500, 300);

      expect(info.details.any((line) => line.contains('Pumpt aktiv')), isTrue);
    });
  });

  group('VoidTraderGame Drohnen-Tick (Roadmap Phase 8)', () {
    // Baut an Position (3,3) mit exakt einem abbaubaren Nachbar-Tile bei
    // (4,3) — dieselbe Ausgangslage wie im Platzierungstest oben, damit
    // beide Tests dasselbe, bekannt-faire Setup teilen.
    Future<VoidTraderGame> buildGameWithOneMinableNeighbor() async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 20);
      game.inventory.add(Resource.ore, 20);
      game.inventory.add(Resource.component, 20);
      final buildPosition = Vector2(3 * VoidTraderGame.tileSize, 3 * VoidTraderGame.tileSize);
      game.simulationWorld.setTileAt(
        4,
        3,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.stone),
      );
      game.buildAt(buildPosition, BuildingType.miningDrone);
      return game;
    }

    // Zyklusdauer ist 6s, Drohnen-Tick-Intervall ist 1s je update()-Aufruf
    // (kein akkumulierender While-Loop) — sieben 1s-Ticks garantieren einen
    // abgeschlossenen Zyklus trotz Fließkomma-Summierung von 1/6, analog zur
    // Begründung in packages/vt_drones/test/drone_test.dart.
    const oneCycleTicks = 7;

    test('vollendeter Abbauzyklus baut das Nachbar-Tile ab und füllt das Inventar', () async {
      final game = await buildGameWithOneMinableNeighbor();
      final oreBefore = game.inventory.count(Resource.stone);

      for (var i = 0; i < oneCycleTicks; i++) {
        game.update(1.0);
      }

      expect(game.inventory.count(Resource.stone), oreBefore + 1);
      expect(
        game.simulationWorld.tileAt(4, 3, vt_world.ZLevel.surface).type.isMinable,
        isFalse,
      );
      final drone = game.drones[(x: 3, y: 3, z: vt_world.ZLevel.surface)];
      expect(drone, isNotNull);
      expect(drone!.status, DroneStatus.working);
    });

    test('Drohne wird erschöpft, sobald keine abbaubaren Nachbarn mehr übrig sind', () async {
      final game = await buildGameWithOneMinableNeighbor();

      // Erster Zyklus baut den einzigen Nachbarn ab, zweiter Zyklus findet
      // keinen mehr.
      for (var i = 0; i < oneCycleTicks * 2; i++) {
        game.update(1.0);
      }

      final drone = game.drones[(x: 3, y: 3, z: vt_world.ZLevel.surface)];
      expect(drone, isNotNull);
      expect(drone!.status, DroneStatus.depleted);
    });

    test('Inspector zeigt Status und Energie einer platzierten Drohne', () async {
      final game = await buildGameWithOneMinableNeighbor();

      final info = game.inspectTile(3, 3);

      expect(info.details.any((line) => line.contains('Arbeitet')), isTrue);
      expect(info.details.any((line) => line.contains('Energie')), isTrue);
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

  group('VoidTraderGame.resourceLabel', () {
    test('liefert für jede Resource ein Label', () {
      for (final resource in Resource.values) {
        expect(VoidTraderGame.resourceLabel(resource), isNotEmpty);
      }
    });
  });

  group('VoidTraderGame.currentInteractionHint', () {
    test('ist null ohne Gebäude auf nicht abbaubarem Tile', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        0,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.grass),
      );

      expect(game.currentInteractionHint(), isNull);
    });

    test('zeigt Abbau-Hinweis auf abbaubarem Tile', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        0,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.stone),
      );

      expect(game.currentInteractionHint(), contains('Abbauen'));
    });

    test('zeigt Craft-Hinweis an einer Werkbank', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.inventory.add(Resource.stone, 2);
      game.inventory.add(Resource.ore, 1);
      game.buildAt(game.player.position, BuildingType.workbench);

      expect(game.currentInteractionHint(), contains('Craften'));
    });

    test('zeigt Abdichten-Hinweis auf geflutetem Tile (Roadmap MVP)', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        0,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.grass, waterLevel: 0.4),
      );

      expect(game.currentInteractionHint(), contains('Abdichten'));
    });
  });

  group('VoidTraderGame.feedbackMessage', () {
    test('meldet Erfolg und Misserfolg beim Bauen', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();

      game.buildAt(game.player.position, BuildingType.wall);
      expect(game.feedbackMessage.value, contains('Nicht genug'));

      game.inventory.add(Resource.stone, 3);
      game.buildAt(game.player.position, BuildingType.wall);
      expect(game.feedbackMessage.value, contains('gebaut'));
    });

    test('meldet erfolgreichen Abbau mit Ressourcenname', () async {
      final game = VoidTraderGame(seed: 1);
      await game.onLoad();
      game.simulationWorld.setTileAt(
        0,
        0,
        vt_world.ZLevel.surface,
        const vt_world.Tile(vt_world.TileType.stone),
      );
      game.player.position = Vector2.zero();

      game.digAt(game.player.position);

      expect(game.feedbackMessage.value, contains('Stein'));
    });
  });
}
