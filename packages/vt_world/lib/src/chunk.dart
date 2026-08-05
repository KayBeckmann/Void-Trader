import 'tile.dart';

/// Koordinate eines Chunks innerhalb einer [Region]/[World] (nicht zu
/// verwechseln mit Welt- oder lokalen Tile-Koordinaten).
class ChunkCoord {
  final int x;
  final int y;

  const ChunkCoord(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is ChunkCoord && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'ChunkCoord($x, $y)';
}

/// Ein Tile-Grid für genau eine z-Ebene innerhalb eines Chunks.
class ChunkLayer {
  final int z;
  final List<List<Tile>> _tiles; // _tiles[localY][localX]

  ChunkLayer(this.z, List<List<Tile>> tiles) : _tiles = tiles;

  Tile tileAt(int localX, int localY) => _tiles[localY][localX];

  void setTile(int localX, int localY, Tile tile) {
    _tiles[localY][localX] = tile;
  }
}

/// Ein quadratischer Ausschnitt der Welt mit mehreren vertikalen Ebenen.
///
/// Chunk-Größe folgt dem Roadmap-Vorschlag (32×32 Tiles).
class Chunk {
  static const int size = 32;

  final ChunkCoord coord;
  final Map<int, ChunkLayer> _layers;

  Chunk(this.coord, Map<int, ChunkLayer> layers) : _layers = layers;

  ChunkLayer layerAt(int z) {
    final layer = _layers[z];
    if (layer == null) {
      throw ArgumentError('Chunk $coord hat keine Ebene z=$z');
    }
    return layer;
  }

  bool hasLayer(int z) => _layers.containsKey(z);

  Iterable<int> get zLevels => _layers.keys;
}
