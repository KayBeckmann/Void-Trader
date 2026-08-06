import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
import 'package:vt_npc/vt_npc.dart';
import 'package:vt_physics/vt_physics.dart';
// Alias nötig: FlameGame definiert selbst einen `world`-Getter/Kamera-World —
// Namenskollision mit vt_world.World.
import 'package:vt_world/vt_world.dart' as vt_world;

import '../ui/tile_inspector_info.dart';
import '../ui/tool_mode.dart';
import 'debug_map_component.dart';
import 'npc_component.dart';
import 'player_component.dart';
import 'tile_highlight_component.dart';
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
/// Zeigt [TileSpriteMapComponent] (Pixel-Art-Tiles + Wasserzustand) als
/// normale Ansicht plus eine steuerbare [PlayerComponent] mit
/// Kamera-Follow. Die Spielfigur bleibt dabei **immer im Bildmittelpunkt**
/// — die Karte rendert stattdessen jeden Frame neu ein Fenster rund um die
/// Spielerposition, die Welt scrollt also unter dem Spieler statt an ein
/// festes Fenster gebunden zu sein (siehe TileSpriteMapComponent).
/// [DebugMapComponent] liegt als schaltbares Debug-Overlay (F1) darüber.
///
/// Interaktionen funktionieren über **zwei gleichwertige Wege** (Roadmap
/// UI-Slice 1): Tastatur (Space/E graben, 1-5 wählt Baumodus + Gebäudetyp,
/// C craften, V verkaufen, L Fracht laden) und Maus/Touch (Klick führt die
/// per [activeTool] gewählte Aktion an der Klickposition aus, siehe
/// [performActionAt]) — beide rufen dieselben Aktionsmethoden auf. Ein
/// periodischer Fluid-Tick ([WorldFluidBridge]) lässt echtes Wasser aus
/// vt_world im sichtbaren Fenster fließen (Phase 3). Ein [DayNightCycle]
/// und ein [WeatherSystem] treiben drei NPCs mit einfacher Tagesroutine an
/// (Phase 5).
class VoidTraderGame extends FlameGame
    with HasKeyboardHandlerComponents, TapCallbacks, PointerMoveCallbacks {
  VoidTraderGame({int seed = 1})
    : simulationWorld = vt_world.World(seed),
      weather = WeatherSystem(seed: seed) {
    // In der Initializer-Liste kann fluidBridge noch nicht auf
    // simulationWorld verweisen (Felder dürfen sich dort nicht gegenseitig
    // referenzieren) — daher hier im Konstruktor-Body zugewiesen, wo
    // simulationWorld bereits gesetzt ist. Beide müssen zwingend dieselbe
    // World-Instanz teilen, sonst simuliert die Fluid-Brücke eine andere
    // Welt als die, in der der Spieler tatsächlich gräbt/läuft.
    fluidBridge = WorldFluidBridge(simulationWorld, vt_world.ZLevel.surface);
  }

  /// Sichtradius der Karte um die Spielfigur (in Tiles). Das gerenderte
  /// Fenster ist damit `2 * _viewRadius + 1` Tiles breit/hoch.
  static const int _viewRadius = 16;

  /// Sekunden zwischen zwei Fluid-Simulationsschritten. Nicht jeden Frame,
  /// damit die Simulation chunk-basiert budgetiert bleibt (Roadmap
  /// Designregel Phase 3) statt jeden Tick das ganze Fenster neu zu bauen.
  static const double _fluidTickInterval = 0.5;

  /// Sekunden zwischen zwei HUD-Aktualisierungen. Das Flutter-Overlay muss
  /// nicht jeden Frame neu bauen, nur oft genug für ein reaktionsfreudiges
  /// Interface.
  static const double _hudTickInterval = 0.2;

  /// Kachelgröße in Pixeln — an die importierten Pixel-Art-Assets angelehnt
  /// (siehe assets/pixel-art/manifest.json), von Sprite- und Debug-Karte
  /// gemeinsam genutzt, damit beide exakt dasselbe Fenster zeigen.
  static const double tileSize = 32;

  final vt_world.World simulationWorld;
  final Inventory inventory = Inventory();
  final Ship ship = Ship();
  final DayNightCycle dayNightCycle = DayNightCycle();
  final WeatherSystem weather;
  final List<Npc> npcs = [];
  late final WorldFluidBridge fluidBridge;
  late final TileSpriteMapComponent spriteMap;
  late final DebugMapComponent map;
  late final TileHighlightComponent tileHighlight;
  late final TileHighlightComponent hoverHighlight;
  late final PlayerComponent player;
  late final List<NpcComponent> npcComponents;

  double _fluidTickAccumulator = 0;
  double _hudTickAccumulator = 0;

  /// Zähler für erfolgreich abgebaute Tiles (nützlich für UI/Debug,
  /// unabhängig vom Inventarstand).
  int minedResourceCount = 0;

  /// Fortschritts-Tracking fürs Ziel-/Tutorialpanel (Roadmap UI-07) —
  /// bewusst als einfache Zähler/Sets statt eines Quest-Systems.
  final Set<BuildingType> builtBuildingTypes = {};
  int totalCrafted = 0;
  bool cargoEverLoaded = false;

  /// Aktiver Toolbelt-Modus (Roadmap UI-04). Bestimmt, was ein Klick auf
  /// die Karte tut — siehe [performActionAt].
  final ValueNotifier<ToolMode> activeTool = ValueNotifier(ToolMode.inspect);

  /// Welches Gebäude im Baumenü ausgewählt ist (Roadmap UI-05), relevant
  /// wenn [activeTool] auf [ToolMode.build] steht.
  final ValueNotifier<BuildingType?> selectedBuildingType = ValueNotifier(null);

  /// Tile unter dem Mauszeiger/Finger (Roadmap UI-03: Hover-Highlight),
  /// `null` wenn außerhalb der Karte oder auf Touch-Geräten ohne Hover.
  final ValueNotifier<({int x, int y})?> hoveredTile = ValueNotifier(null);

  /// Zuletzt angeklicktes Tile (Roadmap UI-03: Selected-Highlight +
  /// Inspector). `null` bis zum ersten Klick — der Inspector fällt in dem
  /// Fall auf die Spielerposition zurück, siehe [inspectedTile].
  final ValueNotifier<({int x, int y})?> selectedTile = ValueNotifier(null);

  /// Erhöht sich periodisch (siehe [_hudTickInterval]) — das Flutter-HUD
  /// hört darauf, um Inventar/Status regelmäßig neu anzuzeigen, ohne dass
  /// jede einzelne Änderung explizit gemeldet werden muss.
  final ValueNotifier<int> hudTick = ValueNotifier(0);

  /// Letzte Rückmeldung zu einer Spieleraktion (Erfolg oder Misserfolg),
  /// für das HUD gedacht — "der Spieler muss mit der Umwelt interagieren
  /// können" heißt auch: er muss sehen, was dabei passiert.
  final ValueNotifier<String?> feedbackMessage = ValueNotifier(null);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Flame sucht Bilder standardmäßig unter "assets/images/" — unsere
    // Pixel-Art liegt unter "assets/pixel-art/" (siehe Manifest dort).
    Flame.images.prefix = 'assets/pixel-art/';

    // Spieler spawnt in der Mitte von Welt-Tile (0,0) — dort liegt die
    // sichere Startzone aus vt_world. Die Karte zentriert sich ab jetzt
    // jeden Frame auf player.position, nicht umgekehrt.
    player = PlayerComponent(
      position: Vector2.all(tileSize / 2),
      onAction: _handleAction,
    );

    spriteMap = TileSpriteMapComponent(
      gameWorld: simulationWorld,
      centerProvider: () => player.position,
      viewRadiusTiles: _viewRadius,
      z: vt_world.ZLevel.surface,
      tileSize: tileSize,
    );

    // Schaltbares Debug-Overlay (F1) — dasselbe mitscrollende Fenster wie
    // spriteMap, standardmäßig aus (siehe DebugMapComponent-Doc).
    map = DebugMapComponent(
      gameWorld: simulationWorld,
      centerProvider: () => player.position,
      viewRadiusTiles: _viewRadius,
      z: vt_world.ZLevel.surface,
      tileSize: tileSize,
    );

    // Visuelle Entsprechung zum HUD-Interaktionshinweis: hebt das Tile
    // hervor, auf das sich currentInteractionHint() gerade bezieht.
    tileHighlight = TileHighlightComponent(
      tileProvider: () =>
          currentInteractionHint() == null ? null : _worldTileFor(player.position),
      tileSize: tileSize,
    );

    // Dünne Hover-Umrandung unter dem Mauszeiger (Roadmap UI-03) — bewusst
    // eine eigene Komponente statt denselben Effekt wie tileHighlight zu
    // teilen, damit Hover und tatsächliche Interaktion visuell klar
    // unterscheidbar bleiben.
    hoverHighlight = TileHighlightComponent(
      tileProvider: () => hoveredTile.value,
      tileSize: tileSize,
      color: const Color(0x99FFFFFF),
      strokeWidth: 2,
    );

    npcComponents = [
      for (final spawn in _npcSpawns) _spawnNpc(spawn.type, spawn.x, spawn.y),
    ];

    // Wichtig: Komponenten müssen in `world` (nicht direkt via `add()` auf
    // dem Game) liegen, damit sie von der Kamera transformiert werden —
    // sonst folgt die Kamera dem Spieler, aber die Karte bleibt starr.
    // Reihenfolge = Zeichenreihenfolge: spriteMap zuunterst, Debug-Overlay
    // und Tile-Hervorhebungen direkt darüber, NPCs/Spieler obenauf.
    await world.addAll([
      spriteMap,
      map,
      hoverHighlight,
      tileHighlight,
      player,
      ...npcComponents,
    ]);

    // snap: true hält den Spieler von Anfang an exakt im Bildmittelpunkt,
    // statt sich der Position erst über die erste(n) Frame(s) anzunähern.
    camera.follow(player, snap: true);
  }

  @override
  void update(double dt) {
    super.update(dt);

    dayNightCycle.update(dt);
    weather.update(dt);
    for (final npc in npcs) {
      npc.tick(dt, isDaytime: dayNightCycle.isDay);
    }

    _hudTickAccumulator += dt;
    if (_hudTickAccumulator >= _hudTickInterval) {
      _hudTickAccumulator -= _hudTickInterval;
      hudTick.value++;
    }

    _fluidTickAccumulator += dt;
    if (_fluidTickAccumulator < _fluidTickInterval) return;
    _fluidTickAccumulator -= _fluidTickInterval;

    final playerTile = _worldTileFor(player.position);
    fluidBridge.step(
      originX: playerTile.x - _viewRadius,
      originY: playerTile.y - _viewRadius,
      width: _viewRadius * 2 + 1,
      height: _viewRadius * 2 + 1,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final worldPosition = camera.globalToLocal(event.canvasPosition);
    selectedTile.value = _worldTileFor(worldPosition);
    performActionAt(worldPosition);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    super.onPointerMove(event);
    final worldPosition = camera.globalToLocal(event.canvasPosition);
    hoveredTile.value = _worldTileFor(worldPosition);
  }

  /// Führt die durch [activeTool] bestimmte Aktion an [worldPosition] aus
  /// (Roadmap UI-04: "Toolbelt-Auswahl bestimmt, was Klick/Leertaste tut").
  /// Ruft dieselben Aktionsmethoden wie die Tastatursteuerung auf — Maus/
  /// Touch und Tastatur lösen also garantiert dasselbe Verhalten aus.
  void performActionAt(Vector2 worldPosition) {
    switch (activeTool.value) {
      case ToolMode.inspect:
        break;
      case ToolMode.dig:
        digAt(worldPosition);
      case ToolMode.build:
        final type = selectedBuildingType.value;
        if (type == null) {
          feedbackMessage.value = 'Zuerst ein Gebäude im Baumenü wählen.';
        } else {
          buildAt(worldPosition, type);
        }
      case ToolMode.craft:
        craftAt(worldPosition);
      case ToolMode.sell:
        sellAllAt(worldPosition);
      case ToolMode.cargo:
        loadCargoAt(worldPosition);
    }
  }

  /// Welches Tile der Inspector gerade zeigen soll: das zuletzt
  /// angeklickte, sonst das unter dem Spieler.
  ({int x, int y}) get inspectedTile => selectedTile.value ?? _worldTileFor(player.position);

  /// Baut die Inspector-Information für ein beliebiges Welt-Tile (Roadmap
  /// UI-03) — unabhängig davon, ob der Spieler dort gerade steht. Zeigt bei
  /// [ToolMode.build] zusätzlich eine Bauvorschau für
  /// [selectedBuildingType], falls dort eines ausgewählt ist.
  TileInspectorInfo inspectTile(int worldX, int worldY) {
    const z = vt_world.ZLevel.surface;
    final tile = simulationWorld.tileAt(worldX, worldY, z);
    final building = simulationWorld.buildingAt(worldX, worldY, z);

    final details = <String>[
      tile.isWalkable ? 'Begehbar' : 'Nicht begehbar',
      if (tile.waterLevel > 0)
        'Wasserstand: ${(tile.waterLevel.clamp(0.0, 1.0) * 100).round()}%',
    ];

    final actions = <InspectorActionInfo>[];
    final String title;

    if (building != null) {
      final definition = buildingDefinitionFor(building);
      title = definition.name;
      switch (building) {
        case BuildingType.workbench:
          final available = inventory.hasAll(basicComponentRecipe.input);
          actions.add(
            InspectorActionInfo(
              label: 'Craften: ${basicComponentRecipe.name}',
              keyHint: 'C',
              available: available,
              blockedReason: available ? null : 'Nicht genug Rohstoffe',
            ),
          );
        case BuildingType.market:
          final canSell = sellPrices.keys.any((r) => inventory.count(r) > 0);
          actions.add(
            InspectorActionInfo(
              label: 'Verkaufen',
              keyHint: 'V',
              available: canSell,
              blockedReason: canSell ? null : 'Nichts zu verkaufen',
            ),
          );
        case BuildingType.landingPad:
          final canLoad = Resource.values.any(
            (r) => r != Resource.credits && inventory.count(r) > 0,
          );
          actions.add(
            InspectorActionInfo(
              label: 'Fracht laden',
              keyHint: 'L',
              available: canLoad,
              blockedReason: canLoad ? null : 'Nichts zu verladen',
            ),
          );
        case BuildingType.wall:
        case BuildingType.storage:
          break;
      }
    } else {
      title = tileTypeLabel(tile.type);
      if (tile.type.isMinable) {
        actions.add(
          const InspectorActionInfo(label: 'Abbauen', keyHint: 'Leertaste', available: true),
        );
      }
    }

    if (building == null &&
        activeTool.value == ToolMode.build &&
        selectedBuildingType.value != null) {
      final type = selectedBuildingType.value!;
      final definition = buildingDefinitionFor(type);
      final canAfford = inventory.hasAll(definition.buildCost);
      final available = tile.isWalkable && canAfford;
      actions.add(
        InspectorActionInfo(
          label: 'Bauen: ${definition.name}',
          keyHint: 'Klick',
          available: available,
          blockedReason: !tile.isWalkable
              ? 'Nicht begehbar'
              : (canAfford ? null : 'Nicht genug Rohstoffe'),
        ),
      );
    }

    return TileInspectorInfo(title: title, details: details, actions: actions);
  }

  /// Deutsches Label für einen Tile-Typ, fürs Inspector-Panel.
  static String tileTypeLabel(vt_world.TileType type) {
    switch (type) {
      case vt_world.TileType.grass:
        return 'Wiese';
      case vt_world.TileType.dirt:
        return 'Erde';
      case vt_world.TileType.stone:
        return 'Stein';
      case vt_world.TileType.water:
        return 'Wasser';
      case vt_world.TileType.forest:
        return 'Wald';
      case vt_world.TileType.farmland:
        return 'Ackerboden';
      case vt_world.TileType.path:
        return 'Weg';
      case vt_world.TileType.rockWall:
        return 'Felswand';
      case vt_world.TileType.empty:
        return 'Leerfläche';
      case vt_world.TileType.caveEntrance:
        return 'Höhleneingang';
      case vt_world.TileType.ore:
        return 'Erzader';
    }
  }

  /// Menschenlesbarer Hinweis, was der Spieler an seiner aktuellen Position
  /// gerade tun kann (fürs HUD) — "der Spieler muss mit der Umwelt
  /// interagieren können" heißt auch: er muss sehen, *womit* gerade.
  /// `null`, wenn hier nichts Interaktives ist.
  String? currentInteractionHint() {
    final tile = _worldTileFor(player.position);
    const z = vt_world.ZLevel.surface;
    final building = simulationWorld.buildingAt(tile.x, tile.y, z);

    if (building == BuildingType.workbench) return '[C] Craften';
    if (building == BuildingType.market) return '[V] Verkaufen';
    if (building == BuildingType.landingPad) return '[L] Fracht laden';

    final tileType = simulationWorld.tileAt(tile.x, tile.y, z).type;
    if (tileType.isMinable) return '[Leertaste] Abbauen';

    return null;
  }

  /// Erzeugt einen [Npc] + zugehörige [NpcComponent] an einer Welt-Tile-
  /// Koordinate relativ zum Ursprung und registriert den Npc in [npcs].
  NpcComponent _spawnNpc(NpcType type, int worldX, int worldY) {
    final npc = Npc(id: '${type.name}-${npcs.length}', type: type);
    npcs.add(npc);
    return NpcComponent(npc: npc, position: _pixelForWorldTile(worldX, worldY));
  }

  /// Pixel-Position der Mitte des Welt-Tiles (worldX, worldY) im
  /// (kameraweiten) Weltkoordinatensystem — jedes Tile liegt fest auf
  /// `worldX * tileSize`, unabhängig davon, welches Kartenfenster gerade
  /// sichtbar ist.
  Vector2 _pixelForWorldTile(int worldX, int worldY) {
    return Vector2((worldX + 0.5) * tileSize, (worldY + 0.5) * tileSize);
  }

  /// Kehrt [_pixelForWorldTile] um: zu welchem Welt-Tile gehört eine
  /// Pixel-Position im Weltkoordinatensystem.
  ({int x, int y}) _worldTileFor(Vector2 position) {
    return (x: (position.x / tileSize).floor(), y: (position.y / tileSize).floor());
  }

  /// Ordnet Tastendrücke den Interaktionen zu. Lebt bewusst im Spiel statt
  /// in [PlayerComponent], damit die Steuerung unabhängig von den
  /// konkreten Interaktionen testbar bleibt.
  ///
  /// Die Zifferntasten bauen NICHT mehr sofort (das tat vor Roadmap UI-04/05
  /// nur diese eine versteckte Tastenkombination) — sie wählen wie ein Klick
  /// auf [ToolbeltPanel]/Baumenü nur noch Werkzeug + Gebäudetyp aus. Die
  /// eigentliche Platzierung passiert einheitlich über [performActionAt]
  /// (Klick/Tap), inklusive Bauvorschau im Inspector. So lösen Tastatur und
  /// UI-Buttons dieselbe Aktion aus, statt zwei parallele, unterschiedlich
  /// funktionierende Bauwege zu pflegen.
  void _handleAction(LogicalKeyboardKey key, Vector2 position) {
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyE) {
      digAt(position);
    } else if (key == LogicalKeyboardKey.digit1) {
      _selectBuildTool(BuildingType.wall);
    } else if (key == LogicalKeyboardKey.digit2) {
      _selectBuildTool(BuildingType.workbench);
    } else if (key == LogicalKeyboardKey.digit3) {
      _selectBuildTool(BuildingType.market);
    } else if (key == LogicalKeyboardKey.digit4) {
      _selectBuildTool(BuildingType.landingPad);
    } else if (key == LogicalKeyboardKey.digit5) {
      _selectBuildTool(BuildingType.storage);
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

  /// Setzt Werkzeug auf Bauen + wählt [type] — dieselbe Wirkung wie ein Tap
  /// auf den passenden Eintrag im Baumenü (Roadmap UI-05).
  void _selectBuildTool(BuildingType type) {
    activeTool.value = ToolMode.build;
    selectedBuildingType.value = type;
  }

  /// Versucht, das Tile unter [worldPosition] (Pixel-Koordinaten im
  /// `world`-Raum der Kamera) abzubauen. Die eigentliche Abbau-Regel lebt
  /// bewusst in vt_world (Dart-Core), hier wird nur Pixel- auf
  /// Welt-Tile-Koordinaten umgerechnet, das Ergebnis gezählt und passende
  /// Rohstoffe ins Inventar gelegt.
  bool digAt(Vector2 worldPosition) {
    final tile = _worldTileFor(worldPosition);
    final mined = simulationWorld.mineTileAt(tile.x, tile.y, vt_world.ZLevel.surface);
    if (mined == null) {
      feedbackMessage.value = 'Hier gibt es nichts abzubauen.';
      return false;
    }

    minedResourceCount++;
    final resource = _resourceForMinedTile(mined);
    if (resource != null) {
      inventory.add(resource, 1);
      feedbackMessage.value = '+1 ${resourceLabel(resource)}';
    }
    return true;
  }

  /// Versucht, [type] unter [worldPosition] zu platzieren — nur wenn die
  /// Baukosten im Inventar vorhanden sind und vt_world die Platzierung
  /// erlaubt (begehbares, unbelegtes Tile). Zieht die Kosten erst nach
  /// erfolgreicher Platzierung ab.
  bool buildAt(Vector2 worldPosition, BuildingType type) {
    final tile = _worldTileFor(worldPosition);
    final definition = buildingDefinitionFor(type);
    if (!inventory.hasAll(definition.buildCost)) {
      feedbackMessage.value = 'Nicht genug Rohstoffe für ${definition.name}.';
      return false;
    }

    final placed = simulationWorld.placeBuildingAt(
      tile.x,
      tile.y,
      vt_world.ZLevel.surface,
      type,
    );
    if (!placed) {
      feedbackMessage.value = 'Hier kann nicht gebaut werden.';
      return false;
    }

    inventory.removeAll(definition.buildCost);
    builtBuildingTypes.add(type);
    feedbackMessage.value = '${definition.name} gebaut.';
    return true;
  }

  /// Craftet [basicComponentRecipe], falls unter [worldPosition] eine
  /// Werkbank steht und genug Rohstoffe vorhanden sind — die erste
  /// vollständige "Sammeln → Verarbeiten"-Stufe der Produktionskette.
  bool craftAt(Vector2 worldPosition) {
    final tile = _worldTileFor(worldPosition);
    final building = simulationWorld.buildingAt(tile.x, tile.y, vt_world.ZLevel.surface);
    if (building != BuildingType.workbench) {
      feedbackMessage.value = 'Hier steht keine Werkbank.';
      return false;
    }
    if (!inventory.hasAll(basicComponentRecipe.input)) {
      feedbackMessage.value = 'Nicht genug Rohstoffe zum Craften.';
      return false;
    }

    inventory.craft(
      basicComponentRecipe.input,
      basicComponentRecipe.output,
      outputAmount: basicComponentRecipe.outputAmount,
    );
    totalCrafted += basicComponentRecipe.outputAmount;
    feedbackMessage.value = '${basicComponentRecipe.name} gecraftet.';
    return true;
  }

  /// Verkauft alle handelbaren Ressourcen im Inventar auf einmal, sofern
  /// unter [worldPosition] ein Marktkiosk steht — "Produktionsüberschuss
  /// kann verkauft werden" aus Phase 6. Gibt die insgesamt erzielten
  /// Credits zurück (0, wenn kein Markt dort steht oder nichts verkäuflich
  /// war).
  int sellAllAt(Vector2 worldPosition) {
    final tile = _worldTileFor(worldPosition);
    final building = simulationWorld.buildingAt(tile.x, tile.y, vt_world.ZLevel.surface);
    if (building != BuildingType.market) {
      feedbackMessage.value = 'Hier steht kein Marktkiosk.';
      return 0;
    }

    var totalEarned = 0;
    for (final resource in sellPrices.keys) {
      final amount = inventory.count(resource);
      if (amount <= 0) continue;
      totalEarned += sellResource(inventory, resource, amount) ?? 0;
    }

    feedbackMessage.value = totalEarned > 0
        ? 'Verkauft für $totalEarned Credits.'
        : 'Nichts zu verkaufen.';
    return totalEarned;
  }

  /// Lädt alle Rohstoffe/Bauteile aus dem Spieler-Inventar ins Schiff,
  /// sofern unter [worldPosition] ein Landepad steht — "Ressourcen vom
  /// Planeten ins Schiff laden" aus Phase 7 (erste Oberfläche↔Orbit-
  /// Brücke). Credits bleiben beim Spieler, sie sind keine physische
  /// Fracht. Gibt die Gesamtmenge geladener Einheiten zurück (0, wenn kein
  /// Landepad dort steht oder nichts zu laden war).
  int loadCargoAt(Vector2 worldPosition) {
    final tile = _worldTileFor(worldPosition);
    final building = simulationWorld.buildingAt(tile.x, tile.y, vt_world.ZLevel.surface);
    if (building != BuildingType.landingPad) {
      feedbackMessage.value = 'Hier steht kein Landepad.';
      return 0;
    }

    var totalLoaded = 0;
    for (final resource in Resource.values) {
      if (resource == Resource.credits) continue;
      final amount = inventory.count(resource);
      if (amount <= 0) continue;
      inventory.remove(resource, amount);
      ship.cargo.add(resource, amount);
      totalLoaded += amount;
    }

    if (totalLoaded > 0) cargoEverLoaded = true;
    feedbackMessage.value = totalLoaded > 0
        ? '$totalLoaded Einheiten Fracht verladen.'
        : 'Nichts zu verladen.';
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

  /// Deutsches Label für eine Ressource, fürs HUD.
  static String resourceLabel(Resource resource) {
    switch (resource) {
      case Resource.stone:
        return 'Stein';
      case Resource.ore:
        return 'Erz';
      case Resource.component:
        return 'Bauteil';
      case Resource.credits:
        return 'Credits';
    }
  }
}
