/// Eine im Inspector-Panel anzeigbare Aktion (Roadmap UI-03): Beschriftung,
/// Tastenkürzel und ob sie gerade möglich ist — inklusive Begründung, wenn
/// nicht ("Grund für gesperrte Aktionen" laut Roadmap-Inspector-Beispiel).
class InspectorActionInfo {
  final String label;
  final String keyHint;
  final bool available;
  final String? blockedReason;

  const InspectorActionInfo({
    required this.label,
    required this.keyHint,
    required this.available,
    this.blockedReason,
  });
}

/// Für das Inspector-Panel aufbereitete Information zu einem Welt-Tile
/// (Roadmap UI-03): Titel, Detailzeilen und verfügbare Aktionen — z.B.
/// "Steinwand — abbaubar — Leertaste: abbauen — Ertrag: Stein".
class TileInspectorInfo {
  final String title;
  final List<String> details;
  final List<InspectorActionInfo> actions;

  const TileInspectorInfo({
    required this.title,
    required this.details,
    required this.actions,
  });
}
