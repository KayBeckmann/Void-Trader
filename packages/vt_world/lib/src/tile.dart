/// Grundlegende Tile-Typen der Planetenoberfläche (Phase 1 der Roadmap).
///
/// Weitere Typen (z.B. Eis, Hydroponik) kommen mit späteren Phasen dazu.
enum TileType {
  grass,
  dirt,
  stone,
  water,
  forest,
  farmland,
  path,
  rockWall,
  empty,
}

/// Ein einzelnes Tile innerhalb einer [ChunkLayer].
///
/// Bewusst leichtgewichtig gehalten (kein Identity-Objekt), damit Chunks
/// günstig generiert und in Tests verglichen werden können.
class Tile {
  final TileType type;

  const Tile(this.type);

  /// Felsige/undurchdringliche Tiles blockieren Bewegung und Sichtlinien.
  bool get isSolid => type == TileType.stone || type == TileType.rockWall;

  bool get isWalkable => !isSolid;

  Tile copyWith({TileType? type}) => Tile(type ?? this.type);

  @override
  bool operator ==(Object other) => other is Tile && other.type == type;

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'Tile(${type.name})';
}
