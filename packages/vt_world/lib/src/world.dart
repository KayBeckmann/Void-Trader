import 'dart:collection';

import 'package:vt_content/vt_content.dart';

import 'biome.dart';
import 'chunk.dart';
import 'noise.dart';
import 'tile.dart';
import 'z_level.dart';

/// Seed-basierte, deterministische Welt aus Chunks.
///
/// Die Oberflächen-Ebene wird über Höhen-/Feuchtigkeits-/Temperatur-Noise
/// generiert (siehe [surfaceTileForBiome]), inklusive seltener
/// Höhleneingänge. Höhlen/Minen (`caves`/`deepCaves`) werden separat
/// ausgehöhlt und enthalten Erzadern — "Generation V1" nach Roadmap Phase 2.
/// Elevierte Ebenen (Berge/Hügel) und der Keller bleiben bewusst uniform.
/// Wichtig bleibt: gleicher Seed + gleiche Chunk-Koordinate erzeugen immer
/// denselben Inhalt.
class World {
  final int seed;
  final Map<ChunkCoord, Chunk> _chunks = {};

  /// Platzierte Gebäude (Roadmap Phase 4), sparse statt chunk-gebunden —
  /// Gebäude sind seltener als Tiles und brauchen keine Generierung.
  final Map<({int x, int y, int z}), BuildingType> _buildings = {};

  // Unabhängige "Kanäle" für die verschiedenen Noise-Karten, damit sie sich
  // trotz gemeinsamem Welt-Seed nicht wie eine einzige Karte verhalten.
  static const int _heightChannel = 0x1000;
  static const int _moistureChannel = 0x2000;
  static const int _temperatureChannel = 0x3000;
  static const int _caveEntranceChannel = 0x4000;
  static const int _caveOpennessChannel = 0x5000;
  static const int _oreChannel = 0x6000;
  static const int _forestGrowthChannel = 0x7000;

  /// Ab diesem Noise-Wert entsteht ein Höhleneingang. Hoch angesetzt, damit
  /// Eingänge selten und kleinflächig bleiben statt große Landstriche zu
  /// bedecken.
  static const double _caveEntranceThreshold = 0.86;

  /// Ab diesem Noise-Wert ist eine unterirdische Zelle ausgehöhlt (begehbar)
  /// statt massiver Fels.
  static const double _caveOpenThreshold = 0.62;

  /// Ab diesem Noise-Wert liegt in einer (nicht ausgehöhlten) Zelle eine
  /// Erzader. Hoch angesetzt, damit Erz selten bleibt.
  static const double _oreThreshold = 0.88;

  /// Ab diesem Noise-Wert wächst an einer Wiesen-Zelle neuer Wald nach
  /// (Roadmap: "Wald sollte sich regenerieren und ausbreiten können", Kays
  /// Feedback 2026-09-27). Sehr hoch angesetzt: [stepForestGrowth] wird oft
  /// aufgerufen (siehe VoidTraderGame._forestGrowthTickInterval), pro
  /// Kandidat-Tile und Aufruf soll trotzdem nur eine kleine Chance
  /// bestehen, sonst wächst gerodeter Wald unrealistisch schnell nach.
  static const double _forestGrowthThreshold = 0.985;

  /// Radius (Chebyshev-Abstand, in Tiles) der sicheren Startzone um den
  /// Weltursprung. Innerhalb garantiert begehbare Wiese ohne Wasser/
  /// Höhleneingang — der Startaußenposten aus der Roadmap.
  static const int _spawnSafeRadius = 4;

  /// Radius eines Puffer-Rings direkt um die sichere Startzone (Roadmap
  /// MOV-04: "Startzonen-Fairness"). Seit Wasser/Wald die Bewegung
  /// blockieren (MOV-01), reichte die reine Wiese-Startzone nicht mehr:
  /// eine noise-generierte Wasser-/Waldfläche direkt außerhalb konnte den
  /// gesamten Bereich vollständig einschließen (empirisch bei zahlreichen
  /// Seeds beobachtet, u.a. dem Standard-Seed 1). Innerhalb dieses Rings
  /// werden Wasser/Wald durch begehbare Alternativen ersetzt, echte
  /// Bergbau-Biome (Stein) bleiben aber erhalten.
  static const int _spawnBufferRadius = 7;

  /// Feste, seed-unabhängige Erz-/Steinvorkommen knapp außerhalb der
  /// sicheren Startzone (Roadmap MOV-04: "Mindestressourcen im
  /// erreichbaren Bereich"). Garantiert, dass jeder Seed von Anfang an
  /// mindestens etwas Abbaubares in Reichweite hat, statt sich auf einen
  /// noise-basierten Höhen-Schwellenwert zu verlassen, der bei manchen
  /// Seeds erst weit entfernt erreicht wird.
  static const List<({int x, int y})> _spawnResourceDeposits = [
    (x: _spawnSafeRadius + 1, y: 0),
    (x: _spawnSafeRadius + 2, y: 0),
    (x: -(_spawnSafeRadius + 1), y: 0),
    (x: -(_spawnSafeRadius + 2), y: 0),
  ];

  /// Ab diesem Höhen-Noise-Wert liegt eine Rampe zu den Hügeln statt
  /// normalem Gelände (Roadmap MOV-03: "Berge/Hügel sind begehbar, aber
  /// verändern die z-Achse"). Knapp unter der Stein-Schwelle in
  /// [surfaceTileForBiome] (0.85) — Rampen liegen so am Rand der ohnehin
  /// schon hochländischen Bereiche, statt zufällig verteilt zu sein.
  static const double _slopeHeightMin = 0.78;

  late final NoiseField _heightNoise;
  late final NoiseField _moistureNoise;
  late final NoiseField _temperatureNoise;
  late final NoiseField _caveEntranceNoise;
  late final NoiseField _caveOpennessNoise;
  late final NoiseField _oreNoise;
  late final NoiseField _forestGrowthNoise;

  World(this.seed) {
    _heightNoise = NoiseField(seed: seed ^ _heightChannel, scale: 40);
    _moistureNoise = NoiseField(seed: seed ^ _moistureChannel, scale: 28);
    _temperatureNoise = NoiseField(seed: seed ^ _temperatureChannel, scale: 60);
    _caveEntranceNoise = NoiseField(seed: seed ^ _caveEntranceChannel, scale: 8);
    _caveOpennessNoise = NoiseField(seed: seed ^ _caveOpennessChannel, scale: 10);
    _oreNoise = NoiseField(seed: seed ^ _oreChannel, scale: 6);
    // scale klein (2): Wachstums-Chancen sollen sich zwischen benachbarten
    // Kandidat-Tiles UND zwischen aufeinanderfolgenden Ticks (siehe
    // zOffset in stepForestGrowth) deutlich unterscheiden, statt großer
    // glatter Flächen wie bei den Biom-Karten.
    _forestGrowthNoise = NoiseField(seed: seed ^ _forestGrowthChannel, scale: 2);
  }

  /// Liefert den Chunk an [coord], generiert ihn deterministisch bei Bedarf.
  Chunk getOrCreateChunk(ChunkCoord coord) {
    return _chunks.putIfAbsent(coord, () => _generateChunk(coord));
  }

  /// Wie [getOrCreateChunk], aber ohne zu generieren — nützlich für Tests
  /// und Debug-Overlays, die nur bereits geladene Chunks anzeigen wollen.
  Chunk? peekChunk(ChunkCoord coord) => _chunks[coord];

  int get loadedChunkCount => _chunks.length;

  /// Liest ein Tile anhand von Welt-Tile-Koordinaten (nicht Chunk-Koordinaten).
  Tile tileAt(int worldX, int worldY, int z) {
    final coord = chunkCoordForWorldTile(worldX, worldY);
    final chunk = getOrCreateChunk(coord);
    final localX = _localCoord(worldX);
    final localY = _localCoord(worldY);
    return chunk.layerAt(z).tileAt(localX, localY);
  }

  /// Wie [tileAt], aber ohne einen fehlenden Chunk zu generieren. Liefert
  /// `null`, wenn der zuständige Chunk noch nicht geladen ist. Gedacht für
  /// Systeme (z.B. eine Fluid-Simulation), die bewusst nur auf bereits
  /// sichtbaren/besuchten Bereichen arbeiten sollen, statt durch reines
  /// Nachschauen neue Chunks zu erzeugen.
  Tile? peekTileAt(int worldX, int worldY, int z) {
    final coord = chunkCoordForWorldTile(worldX, worldY);
    final chunk = peekChunk(coord);
    if (chunk == null) return null;
    final localX = _localCoord(worldX);
    final localY = _localCoord(worldY);
    return chunk.layerAt(z).tileAt(localX, localY);
  }

  /// Schreibt ein Tile anhand von Welt-Tile-Koordinaten.
  void setTileAt(int worldX, int worldY, int z, Tile tile) {
    final coord = chunkCoordForWorldTile(worldX, worldY);
    final chunk = getOrCreateChunk(coord);
    final localX = _localCoord(worldX);
    final localY = _localCoord(worldY);
    chunk.layerAt(z).setTile(localX, localY, tile);
  }

  /// Baut das Tile an den Welt-Tile-Koordinaten ab, falls es abbaubar ist
  /// (siehe [TileMining.isMinable]). Gibt den ursprünglichen [TileType]
  /// zurück (z.B. als Ressourcen-Ertrag), oder `null` wenn dort nichts
  /// abzubauen war.
  TileType? mineTileAt(int worldX, int worldY, int z) {
    final current = tileAt(worldX, worldY, z);
    if (!current.type.isMinable) return null;
    setTileAt(worldX, worldY, z, Tile(current.type.minedResult));
    return current.type;
  }

  /// Verringert den Wasserstand eines Tiles (Roadmap MVP-Definition:
  /// "Spieler kann mit Graben/Pumpe/Abdichten reagieren"). Ohne [amount]
  /// wird das Tile in einem Schritt vollständig trockengelegt (Abdichten-
  /// Sofortaktion); mit [amount] wird höchstens so viel abgepumpt, wie
  /// tatsächlich vorhanden ist (Pumpen-Gebäude, das pro Tick einen festen
  /// Betrag abbaut). Der Tile-Typ selbst bleibt unverändert — nur der
  /// Wasserstand sinkt. Gibt den tatsächlich entfernten Betrag zurück,
  /// oder `null`, wenn das Tile ohnehin trocken war.
  double? drainWaterAt(int worldX, int worldY, int z, [double? amount]) {
    assert(amount == null || amount > 0, 'amount muss positiv sein, falls angegeben');
    final tile = tileAt(worldX, worldY, z);
    if (tile.waterLevel <= 0) return null;
    final drained = amount == null ? tile.waterLevel : amount.clamp(0.0, tile.waterLevel);
    if (drained <= 0) return null;
    setTileAt(worldX, worldY, z, Tile(tile.type, waterLevel: tile.waterLevel - drained));
    return drained;
  }

  /// Platziert ein Gebäude an den Welt-Tile-Koordinaten, falls das Tile
  /// begehbar und noch nicht belegt ist. Gibt `true` bei Erfolg zurück.
  /// Prüft nur die Platzierungsregel — Baukosten/Inventar-Abzug ist Sache
  /// der aufrufenden Schicht (siehe vt_content für Baukosten).
  bool placeBuildingAt(int worldX, int worldY, int z, BuildingType type) {
    final tile = tileAt(worldX, worldY, z);
    if (!tile.isWalkable) return false;

    final key = (x: worldX, y: worldY, z: z);
    if (_buildings.containsKey(key)) return false;

    _buildings[key] = type;
    return true;
  }

  /// Liefert das an den Welt-Tile-Koordinaten platzierte Gebäude, falls
  /// eines existiert.
  BuildingType? buildingAt(int worldX, int worldY, int z) =>
      _buildings[(x: worldX, y: worldY, z: z)];

  /// Prüft, ob normale Bewegung auf die Welt-Tile-Koordinaten erlaubt ist
  /// (Roadmap MOV-02) — berücksichtigt sowohl das Gelände als auch ein
  /// dort platziertes Gebäude. Gibt `null` zurück, wenn die Bewegung
  /// erlaubt ist, sonst eine deutsche UI-Meldung, warum nicht.
  String? movementBlockReasonAt(int worldX, int worldY, int z) {
    final building = buildingAt(worldX, worldY, z);
    if (building != null && building.blocksMovement) {
      return 'Gebäude blockiert den Weg.';
    }
    return tileAt(worldX, worldY, z).type.movementBlockedReason;
  }

  /// Bequemlichkeit für [movementBlockReasonAt]: `true`, wenn der Spieler
  /// sich auf die Welt-Tile-Koordinaten bewegen darf.
  bool canEnter(int worldX, int worldY, int z) =>
      movementBlockReasonAt(worldX, worldY, z) == null;

  /// Flood-Fill aller vom Startpunkt aus über begehbare Tiles erreichbaren
  /// Welt-Tile-Koordinaten, 4-Nachbarschaft (Roadmap MOV-04: Startzonen-
  /// Fairness). Bricht bei [maxTiles] ab statt für sehr offene Karten
  /// unbegrenzt zu wachsen — für die Fairness-Prüfung reicht ein Budget
  /// weit über die garantierte Startzone hinaus, siehe [validateStartZone].
  Set<({int x, int y})> reachableTilesFrom(
    int startX,
    int startY,
    int z, {
    int maxTiles = 2000,
  }) {
    final start = (x: startX, y: startY);
    final visited = <({int x, int y})>{start};
    final queue = Queue<({int x, int y})>()..add(start);

    while (queue.isNotEmpty && visited.length < maxTiles) {
      final current = queue.removeFirst();
      for (final neighbor in _fourNeighbors(current)) {
        if (visited.length >= maxTiles) break;
        if (visited.contains(neighbor)) continue;
        if (!canEnter(neighbor.x, neighbor.y, z)) continue;
        visited.add(neighbor);
        queue.add(neighbor);
      }
    }
    return visited;
  }

  static Iterable<({int x, int y})> _fourNeighbors(({int x, int y}) tile) sync* {
    yield (x: tile.x + 1, y: tile.y);
    yield (x: tile.x - 1, y: tile.y);
    yield (x: tile.x, y: tile.y + 1);
    yield (x: tile.x, y: tile.y - 1);
  }

  /// Entfernt ein platziertes Gebäude. Gibt `true` zurück, falls dort
  /// tatsächlich eines stand.
  bool removeBuildingAt(int worldX, int worldY, int z) =>
      _buildings.remove((x: worldX, y: worldY, z: z)) != null;

  /// Ein Schritt Waldregeneration/-ausbreitung (Roadmap: "Wald sollte sich
  /// regenerieren und ausbreiten können", Kays Feedback 2026-09-27) für ein
  /// rechteckiges Fenster ab ([originX], [originY]) — budgetiert wie
  /// [reachableTilesFrom]/die Fluid-Simulation, nicht die gesamte Welt pro
  /// Aufruf. Jede begehbare Wiese ([TileType.grass]) ohne Gebäude, die
  /// mindestens ein Wald-Tile als Nachbarn hat, bekommt eine kleine Chance,
  /// selbst zu Wald zu werden — dasselbe Muster deckt sowohl "gerodeter
  /// Wald wächst nach" als auch "Wald breitet sich in offenes Grasland aus"
  /// ab, ohne zwei getrennte Systeme zu brauchen.
  ///
  /// [tick] muss bei jedem Aufruf hochgezählt werden (siehe
  /// VoidTraderGame._tickForestGrowth) — er wählt über [NoiseField.zOffset]
  /// ein neues, aber deterministisches Zufallsmuster, sonst würde ein und
  /// dasselbe Tile bei jedem Aufruf entweder immer wachsen oder nie.
  /// Bewusst zweiphasig (erst alle Kandidaten sammeln, dann erst
  /// schreiben): sonst könnte neu gewachsener Wald in derselben Runde schon
  /// wieder als "Nachbar" für das nächste Kandidat-Tile zählen und eine
  /// Kettenreaktion auslösen, die mit einem einzelnen Tick nichts mehr zu
  /// tun hätte.
  void stepForestGrowth({
    required int originX,
    required int originY,
    required int width,
    required int height,
    required int tick,
    int z = ZLevel.surface,
  }) {
    final candidates = <({int x, int y})>[];
    for (var dy = 0; dy < height; dy++) {
      for (var dx = 0; dx < width; dx++) {
        final worldX = originX + dx;
        final worldY = originY + dy;
        if (_isInSpawnSafeZone(worldX, worldY)) continue;
        if (tileAt(worldX, worldY, z).type != TileType.grass) continue;
        if (buildingAt(worldX, worldY, z) != null) continue;
        if (!_hasForestNeighbor(worldX, worldY, z)) continue;
        candidates.add((x: worldX, y: worldY));
      }
    }

    for (final candidate in candidates) {
      final growthValue = _forestGrowthNoise.valueAt(
        candidate.x,
        candidate.y,
        zOffset: tick * 991.0,
      );
      if (growthValue > _forestGrowthThreshold) {
        setTileAt(candidate.x, candidate.y, z, const Tile(TileType.forest));
      }
    }
  }

  bool _hasForestNeighbor(int worldX, int worldY, int z) {
    for (final neighbor in _fourNeighbors((x: worldX, y: worldY))) {
      if (tileAt(neighbor.x, neighbor.y, z).type == TileType.forest) return true;
    }
    return false;
  }

  static ChunkCoord chunkCoordForWorldTile(int worldX, int worldY) {
    return ChunkCoord(_floorDiv(worldX), _floorDiv(worldY));
  }

  static int _floorDiv(int a) => (a - _localCoord(a)) ~/ Chunk.size;

  static int _localCoord(int a) => a % Chunk.size;

  static bool _isInSpawnSafeZone(int worldX, int worldY) =>
      worldX.abs() <= _spawnSafeRadius && worldY.abs() <= _spawnSafeRadius;

  static bool _isInSpawnBufferZone(int worldX, int worldY) =>
      worldX.abs() <= _spawnBufferRadius && worldY.abs() <= _spawnBufferRadius;

  static bool _isSpawnResourceDeposit(int worldX, int worldY) => _spawnResourceDeposits.any(
    (deposit) => deposit.x == worldX && deposit.y == worldY,
  );

  /// Ob an diesen Welt-Tile-Koordinaten die Oberfläche einen Höhleneingang
  /// hätte — dieselbe Regel wie in [_generateSurfaceLayer] (Spawn-Zonen,
  /// Puffer-Ring, Rampen-Vorrang, kein Wasser), aber als eigenständige
  /// Funktion, damit die tieferen Ebenen ([_generateUniformLayer]
  /// für [ZLevel.cellar], [_generateUndergroundLayer] für `caves`/
  /// `deepCaves`) an genau denselben Koordinaten einen durchgehenden
  /// Schacht bis [ZLevel.deepCaves] erzeugen können (Roadmap: "Höhlen und
  /// eine Mechanik, um diese zu betreten"). Ohne diesen durchgehenden
  /// Schacht wäre ein Höhleneingang auf der Oberfläche eine Sackgasse: der
  /// Keller ist uniform, Höhlen/Minen sind noise-ausgehöhlt und hätten an
  /// den meisten Koordinaten schlicht massiven Fels.
  bool _isCaveEntranceAt(int worldX, int worldY) {
    if (_isSpawnResourceDeposit(worldX, worldY)) return false;
    if (_isInSpawnSafeZone(worldX, worldY)) return false;

    final height = _heightNoise.valueAt(worldX, worldY);
    var biomeType = surfaceTileForBiome(
      height: height,
      moisture: _moistureNoise.valueAt(worldX, worldY),
      temperature: _temperatureNoise.valueAt(worldX, worldY),
    );
    if (_isInSpawnBufferZone(worldX, worldY)) {
      if (biomeType == TileType.water) {
        biomeType = TileType.dirt;
      } else if (biomeType == TileType.forest) {
        biomeType = TileType.grass;
      }
    }

    // Rampe hat Vorrang vor Höhleneingang (siehe _generateSurfaceLayer) —
    // beide sind an unterschiedliche Noise-Schwellen gebunden, aber eine
    // Welt-Koordinate kann nicht beides gleichzeitig sein.
    if ((biomeType == TileType.grass || biomeType == TileType.dirt) &&
        height >= _slopeHeightMin) {
      return false;
    }

    // Höhleneingänge nie auf Wasser — sonst müsste man erst tauchen, um in
    // die erste Höhlenebene zu gelangen.
    if (biomeType == TileType.water) return false;

    final entranceValue = _caveEntranceNoise.valueAt(worldX, worldY);
    return entranceValue > _caveEntranceThreshold;
  }

  Chunk _generateChunk(ChunkCoord coord) {
    final layers = <int, ChunkLayer>{ZLevel.surface: _generateSurfaceLayer(coord)};
    for (final z in ZLevel.all) {
      if (z == ZLevel.surface) continue;
      final isDeepUnderground = z == ZLevel.caves || z == ZLevel.deepCaves;
      layers[z] = isDeepUnderground
          ? _generateUndergroundLayer(coord, z)
          : z == ZLevel.hills
          ? _generateHillsLayer(coord)
          : _generateUniformLayer(coord, z);
    }
    return Chunk(coord, layers);
  }

  ChunkLayer _generateSurfaceLayer(ChunkCoord coord) {
    final tiles = List.generate(
      Chunk.size,
      (y) => List.generate(Chunk.size, (x) {
        final worldX = coord.x * Chunk.size + x;
        final worldY = coord.y * Chunk.size + y;

        // Feste Erz-/Steinvorkommen knapp außerhalb der Startzone (Roadmap
        // MOV-04: "Mindestressourcen im erreichbaren Bereich") —
        // unabhängig von Seed/Noise, garantiert jedem Seed von Anfang an
        // etwas Abbaubares in Reichweite.
        if (_isSpawnResourceDeposit(worldX, worldY)) {
          return const Tile(TileType.stone);
        }

        // Startaußenposten in sicherer Zone: unabhängig von Höhe/Feuchte/
        // Höhleneingang immer begehbare Wiese, kein Wasser vor der Haustür.
        if (_isInSpawnSafeZone(worldX, worldY)) {
          return const Tile(TileType.grass);
        }

        final height = _heightNoise.valueAt(worldX, worldY);
        var biomeType = surfaceTileForBiome(
          height: height,
          moisture: _moistureNoise.valueAt(worldX, worldY),
          temperature: _temperatureNoise.valueAt(worldX, worldY),
        );

        // Puffer-Ring um die Startzone (Roadmap MOV-04): Wasser/Wald
        // könnten sonst bei manchen Seeds einen vollständig unpassierbaren
        // Ring rund um die Startzone bilden — seit MOV-01 blockieren beide
        // die Bewegung. Echte Bergbau-Biome (Stein) bleiben unangetastet,
        // nur die beiden Bewegungs-Sperren werden durch begehbare
        // Alternativen ersetzt.
        if (_isInSpawnBufferZone(worldX, worldY)) {
          if (biomeType == TileType.water) {
            biomeType = TileType.dirt;
          } else if (biomeType == TileType.forest) {
            biomeType = TileType.grass;
          }
        }

        // Rampe zu den Hügeln (Roadmap MOV-03) — nur auf offenem Gelände,
        // nicht auf Wasser/Wald. Die passende Rampe auf der Hügel-Ebene
        // entsteht an derselben Welt-Koordinate, siehe
        // [_generateHillsLayer].
        if ((biomeType == TileType.grass || biomeType == TileType.dirt) &&
            height >= _slopeHeightMin) {
          return const Tile(TileType.slope);
        }

        if (_isCaveEntranceAt(worldX, worldY)) {
          return const Tile(TileType.caveEntrance);
        }

        // Wasser-Biom-Tiles starten mit vollem Wasserstand, damit die
        // Fluid-Simulation (Phase 3) echte Seen statt trockener
        // "Wasser"-Etiketten vorfindet.
        final waterLevel = biomeType == TileType.water ? 1.0 : 0.0;
        return Tile(biomeType, waterLevel: waterLevel);
      }),
    );
    return ChunkLayer(ZLevel.surface, tiles);
  }

  /// Einfache, noch nicht durch Noise aufgelöste Ebenen: Berge sind
  /// weiterhin durchgehend Stein und unerreichbar (bewusst außerhalb des
  /// Umfangs von MOV-03 — "Generation V1"). Der Keller (erste Ebene unter
  /// der Oberfläche) ist ansonsten durchgehend Erde, also von jedem
  /// Höhleneingang aus ohne Hindernis betretbar — mit genau einer Ausnahme:
  /// direkt unter einem Oberflächen-Höhleneingang liegt selbst wieder ein
  /// Höhleneingang, der den Schacht nach [ZLevel.caves] fortsetzt (siehe
  /// [_isCaveEntranceAt]). Hügel haben eine eigene Generierung, siehe
  /// [_generateHillsLayer]. Tiefere Ebenen (Höhlen/Minen) werden separat
  /// über [_generateUndergroundLayer] ausgehöhlt.
  ChunkLayer _generateUniformLayer(ChunkCoord coord, int z) {
    final fillType = z == ZLevel.mountains ? TileType.stone : TileType.dirt;
    final tiles = List.generate(
      Chunk.size,
      (y) => List.generate(Chunk.size, (x) {
        if (z == ZLevel.cellar) {
          final worldX = coord.x * Chunk.size + x;
          final worldY = coord.y * Chunk.size + y;
          if (_isCaveEntranceAt(worldX, worldY)) {
            return const Tile(TileType.caveEntrance);
          }
        }
        return Tile(fillType);
      }),
    );
    return ChunkLayer(z, tiles);
  }

  /// Hügel-Ebene (Roadmap MOV-03: "Berge/Hügel sind begehbar, aber
  /// verändern die z-Achse") — begehbares Hochland (Erde) statt massivem
  /// Stein, mit einer Rampe zurück zur Oberfläche an genau den
  /// Welt-Koordinaten, an denen die Oberfläche eine Rampe nach oben hat
  /// (siehe [_generateSurfaceLayer]). Bewusst uniform statt eigenem
  /// Noise-Muster — "Generation V1", die Berge (`z+2`) bleiben wie zuvor
  /// unerreichbarer massiver Stein.
  ChunkLayer _generateHillsLayer(ChunkCoord coord) {
    final tiles = List.generate(
      Chunk.size,
      (y) => List.generate(Chunk.size, (x) {
        final worldX = coord.x * Chunk.size + x;
        final worldY = coord.y * Chunk.size + y;
        final height = _heightNoise.valueAt(worldX, worldY);
        var surfaceBiome = surfaceTileForBiome(
          height: height,
          moisture: _moistureNoise.valueAt(worldX, worldY),
          temperature: _temperatureNoise.valueAt(worldX, worldY),
        );
        // Muss dieselbe Puffer-Ring-Ersetzung wie _generateSurfaceLayer
        // durchlaufen, sonst könnte eine Rampe auf der Oberfläche
        // entstehen (nach der Ersetzung begehbar + hoch genug), ohne eine
        // passende Rampe auf der Hügel-Ebene zu haben.
        if (_isInSpawnBufferZone(worldX, worldY)) {
          if (surfaceBiome == TileType.water) {
            surfaceBiome = TileType.dirt;
          } else if (surfaceBiome == TileType.forest) {
            surfaceBiome = TileType.grass;
          }
        }
        final surfaceHasSlope =
            !_isInSpawnSafeZone(worldX, worldY) &&
            !_isSpawnResourceDeposit(worldX, worldY) &&
            (surfaceBiome == TileType.grass || surfaceBiome == TileType.dirt) &&
            height >= _slopeHeightMin;
        return Tile(surfaceHasSlope ? TileType.slope : TileType.dirt);
      }),
    );
    return ChunkLayer(ZLevel.hills, tiles);
  }

  /// Höhlen/Minen (`caves`, `deepCaves`): überwiegend massiver Fels, mit
  /// noise-basiert ausgehöhlten Gängen/Kammern (begehbar) und seltenen
  /// Erzadern im verbleibenden Gestein. [zOffset] sorgt dafür, dass jede
  /// Ebene ihr eigenes Muster bekommt statt eine reine Kopie der anderen zu
  /// sein, ohne dass echtes 3D-Noise nötig wäre. Direkt unter einem
  /// Oberflächen-Höhleneingang liegt an derselben Welt-Koordinate immer ein
  /// weiterer Höhleneingang statt zufälligem Fels/Gang — das setzt den
  /// Schacht garantiert bis [ZLevel.deepCaves] fort, unabhängig davon, ob
  /// der Openness-Noise an dieser Stelle zufällig einen Gang ausgehöhlt
  /// hätte.
  ChunkLayer _generateUndergroundLayer(ChunkCoord coord, int z) {
    final zOffset = (-z).toDouble() * 137.0;
    final tiles = List.generate(
      Chunk.size,
      (y) => List.generate(Chunk.size, (x) {
        final worldX = coord.x * Chunk.size + x;
        final worldY = coord.y * Chunk.size + y;

        if (_isCaveEntranceAt(worldX, worldY)) {
          return const Tile(TileType.caveEntrance);
        }

        final openness = _caveOpennessNoise.valueAt(worldX, worldY, zOffset: zOffset);
        if (openness > _caveOpenThreshold) {
          return const Tile(TileType.path);
        }

        final oreChance = _oreNoise.valueAt(worldX, worldY, zOffset: zOffset);
        if (oreChance > _oreThreshold) {
          return const Tile(TileType.ore);
        }

        return const Tile(TileType.rockWall);
      }),
    );
    return ChunkLayer(z, tiles);
  }
}
