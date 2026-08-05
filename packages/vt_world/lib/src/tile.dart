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

  /// Höhleneingang auf der Oberfläche (Phase 2: prozedurale Weltgeneration).
  /// Begehbar — markiert den Übergang zur ersten Höhlenebene darunter.
  caveEntrance,

  /// Erzader in tieferen Ebenen (Phase 2). Solide wie Fels, aber abbaubar
  /// und liefert einen eigenen Ressourcentyp statt gewöhnlichem Gestein.
  ore,
}

/// Ein einzelnes Tile innerhalb einer [ChunkLayer].
///
/// Bewusst leichtgewichtig gehalten (kein Identity-Objekt), damit Chunks
/// günstig generiert und in Tests verglichen werden können.
class Tile {
  final TileType type;

  /// Wasserstand auf/in diesem Tile (Phase 3: Oberflächen-Physikengine).
  /// Immer `0` für solide Tiles — Fels hält kein Wasser über sich.
  final double waterLevel;

  const Tile(this.type, {this.waterLevel = 0})
    : assert(waterLevel >= 0, 'waterLevel darf nicht negativ sein'),
      assert(
        waterLevel == 0 ||
            (type != TileType.stone &&
                type != TileType.rockWall &&
                type != TileType.ore),
        'Solide Tiles ($type) dürfen kein Wasser halten',
      );

  /// Felsige/undurchdringliche Tiles blockieren Bewegung und Sichtlinien.
  bool get isSolid =>
      type == TileType.stone || type == TileType.rockWall || type == TileType.ore;

  bool get isWalkable => !isSolid;

  Tile copyWith({TileType? type, double? waterLevel}) =>
      Tile(type ?? this.type, waterLevel: waterLevel ?? this.waterLevel);

  @override
  bool operator ==(Object other) =>
      other is Tile && other.type == type && other.waterLevel == waterLevel;

  @override
  int get hashCode => Object.hash(type, waterLevel);

  @override
  String toString() => 'Tile(${type.name}, water: $waterLevel)';
}

/// Regeln für das erste Interaktionswerkzeug (Graben/Abbauen, Phase 1).
///
/// Bewusst als reine Funktionen auf [TileType] statt in der Flame-Schicht,
/// damit "was ist abbaubar" ohne Rendering testbar ist (siehe
/// docs/ARCHITECTURE.md: "Dart-Core zuerst").
extension TileMining on TileType {
  /// Ob dieses Tile mit dem Graben/Abbauen-Werkzeug entfernt werden kann.
  bool get isMinable =>
      this == TileType.stone || this == TileType.rockWall || this == TileType.ore;

  /// Tile-Typ, der nach erfolgreichem Abbau zurückbleibt.
  TileType get minedResult {
    assert(isMinable, 'minedResult nur für abbaubare Tiles ($this) aufrufen');
    return TileType.path;
  }
}
