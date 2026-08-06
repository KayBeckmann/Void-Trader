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

  /// Begehbare Rampe zwischen Oberfläche und Hügeln (Roadmap MOV-03:
  /// "Berge/Hügel sind begehbar, aber verändern die z-Achse"). Blockiert
  /// weder Bewegung noch Sicht — die z-Änderung beim Betreten ist
  /// Spielschicht-Logik (siehe VoidTraderGame), nicht Teil des Tiles
  /// selbst.
  slope,
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

  /// Felsige/undurchdringliche Tiles — physisch fest, nicht dasselbe wie
  /// "blockiert Bewegung" (siehe [TileMovement.blocksMovement]): Wasser ist
  /// z.B. nicht solide, blockiert aber seit der Sofort-Korrektur
  /// "Bewegung, Kollision, Startzone und Sicht/Fog of War" trotzdem die
  /// normale Bewegung.
  bool get isSolid =>
      type == TileType.stone || type == TileType.rockWall || type == TileType.ore;

  /// Ob der Spieler sich normal auf dieses Tile bewegen kann (Roadmap
  /// MOV-01). Bewusst über [TileMovement.blocksMovement] definiert statt
  /// über [isSolid] — Wasser und Wald sind nicht solide, blockieren aber
  /// trotzdem die Bewegung.
  bool get isWalkable => !type.blocksMovement;

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

/// Bewegungs-/Sicht-Eigenschaften je Tile-Typ (Roadmap-Block "Bewegung,
/// Kollision, Startzone und Sicht/Fog of War", MOV-01) — bewusst als reine
/// Funktionen auf [TileType] statt in der Flame-Schicht, damit die Regeln
/// ohne Rendering testbar sind ("Dart-Core zuerst").
extension TileMovement on TileType {
  /// Ob dieses Tile die normale Bewegung blockiert. Physisch festes
  /// Gestein blockierte schon vorher (nur bisher nicht durchgesetzt, siehe
  /// [Tile.isWalkable]); neu dazugekommen sind Wasser und dichter Wald —
  /// beide sind nicht "solide" im Sinn von [Tile.isSolid], sollen den
  /// Spieler aber trotzdem nicht ungebremst durchlaufen lassen.
  bool get blocksMovement {
    switch (this) {
      case TileType.stone:
      case TileType.rockWall:
      case TileType.ore:
      case TileType.water:
      case TileType.forest:
        return true;
      case TileType.grass:
      case TileType.dirt:
      case TileType.farmland:
      case TileType.path:
      case TileType.empty:
      case TileType.caveEntrance:
      case TileType.slope:
        return false;
    }
  }

  /// Ob dieses Tile Sichtlinien blockiert (Roadmap FOW-03). Bewusst
  /// unabhängig von [blocksMovement]: Wasser blockiert die Bewegung, aber
  /// nicht den Blick über einen See hinweg.
  bool get blocksSight {
    switch (this) {
      case TileType.stone:
      case TileType.rockWall:
      case TileType.ore:
      case TileType.forest:
        return true;
      case TileType.grass:
      case TileType.dirt:
      case TileType.farmland:
      case TileType.path:
      case TileType.water:
      case TileType.empty:
      case TileType.caveEntrance:
      case TileType.slope:
        return false;
    }
  }

  /// Deutsche UI-Meldung, warum dieses Tile die Bewegung blockiert —
  /// `null`, wenn es das nicht tut. Getrennt von [blocksMovement] statt
  /// generischem Text, weil die Roadmap unterschiedliche Meldungen je
  /// Hindernistyp verlangt ("Wasser blockiert den Weg", "Baum blockiert
  /// den Weg", "Felswand blockiert den Weg").
  String? get movementBlockedReason {
    switch (this) {
      case TileType.water:
        return 'Wasser blockiert den Weg.';
      case TileType.forest:
        return 'Baum blockiert den Weg.';
      case TileType.stone:
      case TileType.rockWall:
      case TileType.ore:
        return 'Felswand blockiert den Weg.';
      case TileType.grass:
      case TileType.dirt:
      case TileType.farmland:
      case TileType.path:
      case TileType.empty:
      case TileType.caveEntrance:
      case TileType.slope:
        return null;
    }
  }
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
