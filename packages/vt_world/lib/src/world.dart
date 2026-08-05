import 'dart:math';

import 'chunk.dart';
import 'tile.dart';
import 'z_level.dart';

/// Seed-basierte, deterministische Welt aus Chunks.
///
/// Phase 1 liefert nur das Datenmodell plus einen bewusst simplen
/// Platzhalter-Generator (überwiegend Gras auf der Oberfläche, Fels
/// darunter/darüber). Die eigentliche prozedurale Generierung (Biome,
/// Höhen-/Feuchtigkeitskarten, Höhlen) folgt in Phase 2. Wichtig ist hier:
/// gleicher Seed + gleiche Chunk-Koordinate erzeugen immer denselben Inhalt.
class World {
  final int seed;
  final Map<ChunkCoord, Chunk> _chunks = {};

  World(this.seed);

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
    final layers = <int, ChunkLayer>{};
    for (final z in ZLevel.all) {
      layers[z] = _generateLayer(coord, z);
    }
    return Chunk(coord, layers);
  }

  ChunkLayer _generateLayer(ChunkCoord coord, int z) {
    final rng = Random(_layerSeed(coord, z));
    final tiles = List.generate(
      Chunk.size,
      (_) => List.generate(Chunk.size, (_) => Tile(_defaultTileFor(z, rng))),
    );
    return ChunkLayer(z, tiles);
  }

  int _layerSeed(ChunkCoord coord, int z) =>
      Object.hash(seed, coord.x, coord.y, z);

  TileType _defaultTileFor(int z, Random rng) {
    if (z == ZLevel.surface) {
      return rng.nextDouble() < 0.85 ? TileType.grass : TileType.dirt;
    }
    if (z > ZLevel.surface) {
      return TileType.stone;
    }
    if (z == ZLevel.cellar) {
      return TileType.dirt;
    }
    // caves / deepCaves: standardmäßig massiver Fels, wird später
    // (Phase 2/3) durch Höhlengenerierung ausgehöhlt.
    return TileType.rockWall;
  }
}
