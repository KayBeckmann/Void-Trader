import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
import 'package:vt_npc/vt_npc.dart';
import 'package:vt_physics/vt_physics.dart';
// Alias nötig: FlameGame definiert selbst einen `world`-Getter/Kamera-World —
// Namenskollision mit vt_world.World.
import 'package:vt_world/vt_world.dart' as vt_world;

import 'debug_map_component.dart';
import 'npc_component.dart';
import 'player_component.dart';
import 'tile_sprite_map_component.dart';

/// Startpositionen der ersten NPCs, relativ zum Weltursprung (in Tiles) —
/// alle innerhalb der sicheren Startzone aus vt_world.
const _npcSpawns = [
  (type: NpcType.farmer, x: -3, y: -3),
  (type: NpcType.miner, x: 3, y: -3),
  (type: NpcType.mechanic, x: 0, y: 3),
];

/// Root Flame game.
///
/// Zeigt [TileSpriteMapComponent] (Pixel-Art-Tiles + Wasserzustand rund um
/// den Weltursprung, dort liegt die sichere Startzone aus vt_world) als
/// normale Ansicht plus eine steuerbare [PlayerComponent] mit
/// Kamera-Follow. [DebugMapComponent] liegt als schaltbares Debug-Overlay
/// (F1) darüber — Sofort-Korrektur nach Webpreview 2026-08-05. Interaktionen:
/// Graben/Abbauen (Space/E, Phase 1), Bauen (1 = Mauer, 2 = Werkbank, 3 =
/// Marktkiosk, 4 = Landepad), Craften (C an einer Werkbank), Verkaufen (V an
/// einem Marktkiosk) und Fracht laden (L an einem Landepad, Phase 7). Ein
/// periodischer Fluid-Tick ([WorldFluidBridge]) lässt echtes Wasser aus
/// vt_world im sichtbaren Fenster fließen (Phase 3). Ein [DayNightCycle]
/// treibt drei NPCs mit einfacher Tagesroutine an (Phase 5).
class VoidTraderGame extends FlameGame with HasKeyboardHandlerComponents {
  VoidTraderGame({int seed = 1}) : simulationWorld = vt_world.World(seed) {
    // In der Initializer-Liste kann fluidBridge noch nicht auf
    // simulationWorld verweisen (Felder dürfen sich dort nicht gegenseitig
    // referenzieren) — daher hier im Konstruktor-Body zugewiesen, wo
    // simulationWorld bereits gesetzt ist. Beide müssen zwingend dieselbe
    // World-Instanz teilen, sonst simuliert die Fluid-Brücke eine andere
    // Welt als die, in der der Spieler tatsächlich gräbt/läuft.
    fluidBridge = WorldFluidBridge(simulationWorld, vt_world.ZLevel.surface);
  }

  /// Radius des Debug-Fensters um den Weltursprung (in Tiles). Das Fenster
  /// ist damit `2 * _viewRadius` Tiles breit/hoch und zentriert auf (0,0) —
  /// dieselbe sichere Startzone, die vt_world garantiert.
  static const int _viewRadius = 16;

  /// Sekunden zwischen zwei Fluid-Simulationsschritten. Nicht jeden Frame,
  /// damit die Simulation chunk-basiert budgetiert bleibt (Roadmap
  /// Designregel Phase 3) statt jeden Tick das ganze Fenster neu zu bauen.
  static const double _fluidTickInterval = 0.5;

  /// Kachelgröße in Pixeln — an die importierten Pixel-Art-Assets angelehnt
  /// (siehe assets/pixel-art/manifest.json), von Sprite- und Debug-Karte
  /// gemeinsam genutzt, damit beide exakt dasselbe Fenster zeigen.
  static const double _tileSize = 32;

  final vt_world.World simulationWorld;
  final Inventory inventory = Inventory();
  final Ship ship = Ship();
  final DayNightCycle dayNightCycle = DayNightCycle();
  final List<Npc> npcs = [];
  late final WorldFluidBridge fluidBridge;
  late final TileSpriteMapComponent spriteMap;
  late final DebugMapComponent map;
  late final PlayerComponent player;
  late final List<NpcComponent> npcComponents;

  double _fluidTickAccumulator = 0;

  /// Zähler für erfolgreich abgebaute Tiles (nützlich für UI/Debug,
  /// unabhängig vom Inventarstand).
  int minedResourceCount = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Flame sucht Bilder standardmäßig unter "assets/images/" — unsere
    // Pixel-Art liegt unter "assets/pixel-art/" (siehe Manifest dort).
    Flame.images.prefix = 'assets/pixel-art/';

    const viewSize = _viewRadius * 2;

    spriteMap = TileSpriteMapComponent(
      gameWorld: simulationWorld,
      originX: -_viewRadius,
      originY: -_viewRadius,
      tileWidth: viewSize,
      tileHeight: viewSize,
      z: vt_world.ZLevel.surface,
      tileSize: _tileSize,
    );

    // Schaltbares Debug-Overlay (F1) — dasselbe Fenster wie spriteMap,
    // standardmäßig aus (siehe DebugMapComponent-Doc).
    map = DebugMapComponent(
      gameWorld: simulationWorld,
      originX: -_viewRadius,
      originY: -_viewRadius,
      tileWidth: viewSize,
      tileHeight: viewSize,
      z: vt_world.ZLevel.surface,
      tileSize: _tileSize,
    );

    // map.size / 2 entspricht damit exakt Welt-Tile (0,0) — Mitte der
    // sicheren Startzone.
    player = PlayerComponent(position: map.size / 2, onAction: _handleAction);

    npcComponents = [
      for (final spawn in _npcSpawns) _spawnNpc(spawn.type, spawn.x, spawn.y),
    ];

    // Wichtig: Komponenten müssen in `world` (nicht direkt via `add()` auf
    // dem Game) liegen, damit sie von der Kamera transformiert werden —
    // sonst folgt die Kamera dem Spieler, aber die Karte bleibt starr.
    // Reihenfolge = Zeichenreihenfolge: spriteMap zuunterst, Debug-Overlay
    // direkt darüber, NPCs/Spieler obenauf.
    await world.addAll([spriteMap, map, player, ...npcComponents]);
    camera.follow(player);
  }

  @override
  void update(double dt) {
    super.update(dt);

    dayNightCycle.update(dt);
    for (final npc in npcs) {
      npc.tick(dt, isDaytime: dayNightCycle.isDay);
    }

    _fluidTickAccumulator += dt;
    if (_fluidTickAccumulator < _fluidTickInterval) return;
    _fluidTickAccumulator -= _fluidTickInterval;

    fluidBridge.step(
      originX: map.originX,
      originY: map.originY,
      width: map.tileWidth,
      height: map.tileHeight,
    );
  }

  /// Erzeugt einen [Npc] + zugehörige [NpcComponent] an einer Welt-Tile-
  /// Koordinate relativ zum Ursprung und registriert den Npc in [npcs].
  NpcComponent _spawnNpc(NpcType type, int offsetX, int offsetY) {
    final npc = Npc(id: '${type.name}-${npcs.length}', type: type);
    npcs.add(npc);
    return NpcComponent(npc: npc, position: _pixelForWorldTile(offsetX, offsetY));
  }

  Vector2 _pixelForWorldTile(int worldX, int worldY) {
    return Vector2(
      (worldX - map.originX) * map.tileSize,
      (worldY - map.originY) * map.tileSize,
    );
  }

  /// Ordnet Tastendrücke den Interaktionen zu. Lebt bewusst im Spiel statt
  /// in [PlayerComponent], damit die Steuerung unabhängig von den
  /// konkreten Interaktionen testbar bleibt.
  void _handleAction(LogicalKeyboardKey key, Vector2 position) {
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyE) {
      digAt(position);
    } else if (key == LogicalKeyboardKey.digit1) {
      buildAt(position, BuildingType.wall);
    } else if (key == LogicalKeyboardKey.digit2) {
      buildAt(position, BuildingType.workbench);
    } else if (key == LogicalKeyboardKey.digit3) {
      buildAt(position, BuildingType.market);
    } else if (key == LogicalKeyboardKey.digit4) {
      buildAt(position, BuildingType.landingPad);
    } else if (key == LogicalKeyboardKey.keyC) {
      craftAt(position);
    } else if (key == LogicalKeyboardKey.keyV) {
      sellAllAt(position);
    } else if (key == LogicalKeyboardKey.keyL) {
      loadCargoAt(position);
    } else if (key == LogicalKeyboardKey.f1) {
      map.enabled = !map.enabled;
    }
  }

  /// Versucht, das Tile unter [worldPosition] (Pixel-Koordinaten im
  /// `world`-Raum der Kamera) abzubauen. Die eigentliche Abbau-Regel lebt
  /// bewusst in vt_world (Dart-Core), hier wird nur Pixel- auf
  /// Welt-Tile-Koordinaten umgerechnet, das Ergebnis gezählt und passende
  /// Rohstoffe ins Inventar gelegt.
  bool digAt(Vector2 worldPosition) {
    final tileX = map.originX + (worldPosition.x / map.tileSize).floor();
    final tileY = map.originY + (worldPosition.y / map.tileSize).floor();
    final mined = simulationWorld.mineTileAt(
      tileX,
      tileY,
      vt_world.ZLevel.surface,
    );
    if (mined == null) return false;

    minedResourceCount++;
    final resource = _resourceForMinedTile(mined);
    if (resource != null) inventory.add(resource, 1);
    return true;
  }

  /// Versucht, [type] unter [worldPosition] zu platzieren — nur wenn die
  /// Baukosten im Inventar vorhanden sind und vt_world die Platzierung
  /// erlaubt (begehbares, unbelegtes Tile). Zieht die Kosten erst nach
  /// erfolgreicher Platzierung ab.
  bool buildAt(Vector2 worldPosition, BuildingType type) {
    final tileX = map.originX + (worldPosition.x / map.tileSize).floor();
    final tileY = map.originY + (worldPosition.y / map.tileSize).floor();
    final cost = buildingDefinitionFor(type).buildCost;
    if (!inventory.hasAll(cost)) return false;

    final placed = simulationWorld.placeBuildingAt(
      tileX,
      tileY,
      vt_world.ZLevel.surface,
      type,
    );
    if (!placed) return false;

    inventory.removeAll(cost);
    return true;
  }

  /// Craftet [basicComponentRecipe], falls unter [worldPosition] eine
  /// Werkbank steht und genug Rohstoffe vorhanden sind — die erste
  /// vollständige "Sammeln → Verarbeiten"-Stufe der Produktionskette.
  bool craftAt(Vector2 worldPosition) {
    final tileX = map.originX + (worldPosition.x / map.tileSize).floor();
    final tileY = map.originY + (worldPosition.y / map.tileSize).floor();
    final building = simulationWorld.buildingAt(tileX, tileY, vt_world.ZLevel.surface);
    if (building != BuildingType.workbench) return false;
    if (!inventory.hasAll(basicComponentRecipe.input)) return false;

    inventory.craft(
      basicComponentRecipe.input,
      basicComponentRecipe.output,
      outputAmount: basicComponentRecipe.outputAmount,
    );
    return true;
  }

  /// Verkauft alle handelbaren Ressourcen im Inventar auf einmal, sofern
  /// unter [worldPosition] ein Marktkiosk steht — "Produktionsüberschuss
  /// kann verkauft werden" aus Phase 6. Gibt die insgesamt erzielten
  /// Credits zurück (0, wenn kein Markt dort steht oder nichts verkäuflich
  /// war).
  int sellAllAt(Vector2 worldPosition) {
    final tileX = map.originX + (worldPosition.x / map.tileSize).floor();
    final tileY = map.originY + (worldPosition.y / map.tileSize).floor();
    final building = simulationWorld.buildingAt(tileX, tileY, vt_world.ZLevel.surface);
    if (building != BuildingType.market) return 0;

    var totalEarned = 0;
    for (final resource in sellPrices.keys) {
      final amount = inventory.count(resource);
      if (amount <= 0) continue;
      totalEarned += sellResource(inventory, resource, amount) ?? 0;
    }
    return totalEarned;
  }

  /// Lädt alle Rohstoffe/Bauteile aus dem Spieler-Inventar ins Schiff,
  /// sofern unter [worldPosition] ein Landepad steht — "Ressourcen vom
  /// Planeten ins Schiff laden" aus Phase 7 (erste Oberfläche↔Orbit-
  /// Brücke). Credits bleiben beim Spieler, sie sind keine physische
  /// Fracht. Gibt die Gesamtmenge geladener Einheiten zurück (0, wenn kein
  /// Landepad dort steht oder nichts zu laden war).
  int loadCargoAt(Vector2 worldPosition) {
    final tileX = map.originX + (worldPosition.x / map.tileSize).floor();
    final tileY = map.originY + (worldPosition.y / map.tileSize).floor();
    final building = simulationWorld.buildingAt(tileX, tileY, vt_world.ZLevel.surface);
    if (building != BuildingType.landingPad) return 0;

    var totalLoaded = 0;
    for (final resource in Resource.values) {
      if (resource == Resource.credits) continue;
      final amount = inventory.count(resource);
      if (amount <= 0) continue;
      inventory.remove(resource, amount);
      ship.cargo.add(resource, amount);
      totalLoaded += amount;
    }
    return totalLoaded;
  }

  /// Welcher Rohstoff (falls überhaupt einer) beim Abbau von [type] anfällt.
  /// Fels aus Bergen (`stone`) und Höhlenwänden (`rockWall`) liefert
  /// dasselbe Material, nur Erzadern liefern `ore`.
  Resource? _resourceForMinedTile(vt_world.TileType type) {
    switch (type) {
      case vt_world.TileType.stone:
      case vt_world.TileType.rockWall:
        return Resource.stone;
      case vt_world.TileType.ore:
        return Resource.ore;
      default:
        return null;
    }
  }
}
