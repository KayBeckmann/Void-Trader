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

  // Unabhängige "Kanäle" für die verschiedenen Noise-Karten, damit sie sich
  // trotz gemeinsamem Welt-Seed nicht wie eine einzige Karte verhalten.
  static const int _heightChannel = 0x1000;
  static const int _moistureChannel = 0x2000;
  static const int _temperatureChannel = 0x3000;
  static const int _caveEntranceChannel = 0x4000;
  static const int _caveOpennessChannel = 0x5000;
  static const int _oreChannel = 0x6000;

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

  late final NoiseField _heightNoise;
  late final NoiseField _moistureNoise;
  late final NoiseField _temperatureNoise;
  late final NoiseField _caveEntranceNoise;
  late final NoiseField _caveOpennessNoise;
  late final NoiseField _oreNoise;

  World(this.seed) {
    _heightNoise = NoiseField(seed: seed ^ _heightChannel, scale: 40);
    _moistureNoise = NoiseField(seed: seed ^ _moistureChannel, scale: 28);
    _temperatureNoise = NoiseField(seed: seed ^ _temperatureChannel, scale: 60);
    _caveEntranceNoise = NoiseField(seed: seed ^ _caveEntranceChannel, scale: 8);
    _caveOpennessNoise = NoiseField(seed: seed ^ _caveOpennessChannel, scale: 10);
    _oreNoise = NoiseField(seed: seed ^ _oreChannel, scale: 6);
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

  static ChunkCoord chunkCoordForWorldTile(int worldX, int worldY) {
    return ChunkCoord(_floorDiv(worldX), _floorDiv(worldY));
  }

  static int _floorDiv(int a) => (a - _localCoord(a)) ~/ Chunk.size;

  static int _localCoord(int a) => a % Chunk.size;

  Chunk _generateChunk(ChunkCoord coord) {
    final layers = <int, ChunkLayer>{ZLevel.surface: _generateSurfaceLayer(coord)};
    for (final z in ZLevel.all) {
      if (z == ZLevel.surface) continue;
      final isDeepUnderground = z == ZLevel.caves || z == ZLevel.deepCaves;
      layers[z] = isDeepUnderground
          ? _generateUndergroundLayer(coord, z)
          : _generateUniformLayer(z);
    }
    return Chunk(coord, layers);
  }

  ChunkLayer _generateSurfaceLayer(ChunkCoord coord) {
    final tiles = List.generate(
      Chunk.size,
      (y) => List.generate(Chunk.size, (x) {
        final worldX = coord.x * Chunk.size + x;
        final worldY = coord.y * Chunk.size + y;
        final biomeType = surfaceTileForBiome(
          height: _heightNoise.valueAt(worldX, worldY),
          moisture: _moistureNoise.valueAt(worldX, worldY),
          temperature: _temperatureNoise.valueAt(worldX, worldY),
        );

        // Höhleneingänge nie auf Wasser platzieren — sonst müsste man erst
        // tauchen, um in die erste Höhlenebene zu gelangen.
        if (biomeType != TileType.water) {
          final entranceValue = _caveEntranceNoise.valueAt(worldX, worldY);
          if (entranceValue > _caveEntranceThreshold) {
            return const Tile(TileType.caveEntrance);
          }
        }

        return Tile(biomeType);
      }),
    );
    return ChunkLayer(ZLevel.surface, tiles);
  }

  /// Einfache, noch nicht durch Noise aufgelöste Ebenen: Berge/Hügel sind
  /// durchgehend Stein. Der Keller (erste Ebene unter der Oberfläche) ist
  /// durchgehend Erde, also von jedem Höhleneingang aus ohne Hindernis
  /// betretbar. Tiefere Ebenen (Höhlen/Minen) werden separat über
  /// [_generateUndergroundLayer] ausgehöhlt.
  ChunkLayer _generateUniformLayer(int z) {
    final type = z > ZLevel.surface ? TileType.stone : TileType.dirt;
    final tiles = List.generate(
      Chunk.size,
      (_) => List.generate(Chunk.size, (_) => Tile(type)),
    );
    return ChunkLayer(z, tiles);
  }

  /// Höhlen/Minen (`caves`, `deepCaves`): überwiegend massiver Fels, mit
  /// noise-basiert ausgehöhlten Gängen/Kammern (begehbar) und seltenen
  /// Erzadern im verbleibenden Gestein. [zOffset] sorgt dafür, dass jede
  /// Ebene ihr eigenes Muster bekommt statt eine reine Kopie der anderen zu
  /// sein, ohne dass echtes 3D-Noise nötig wäre.
  ChunkLayer _generateUndergroundLayer(ChunkCoord coord, int z) {
    final zOffset = (-z).toDouble() * 137.0;
    final tiles = List.generate(
      Chunk.size,
      (y) => List.generate(Chunk.size, (x) {
        final worldX = coord.x * Chunk.size + x;
        final worldY = coord.y * Chunk.size + y;

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
