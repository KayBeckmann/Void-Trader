/// Aktiver Interaktionsmodus der Toolbelt (Roadmap UI-04: "Toolbelt-Auswahl
/// bestimmt, was Klick/Leertaste tut").
///
/// `inspect` wählt nur ein Tile aus und aktualisiert den Inspector, ohne
/// eine Aktion auszulösen — alle anderen Modi lösen beim Klick auf ein
/// Tile die jeweilige Aktion an genau dieser Position aus.
enum ToolMode { inspect, dig, build, craft, sell, cargo }

/// Deutsches Label + Tastenkürzel je Modus, fürs Toolbelt-UI.
extension ToolModeLabels on ToolMode {
  String get label {
    switch (this) {
      case ToolMode.inspect:
        return 'Bewegen/Inspizieren';
      case ToolMode.dig:
        return 'Abbauen';
      case ToolMode.build:
        return 'Bauen';
      case ToolMode.craft:
        return 'Craften';
      case ToolMode.sell:
        return 'Verkaufen';
      case ToolMode.cargo:
        return 'Fracht laden';
    }
  }

  String get keyHint {
    switch (this) {
      case ToolMode.inspect:
        return '';
      case ToolMode.dig:
        return 'Leertaste';
      case ToolMode.build:
        return '1-5';
      case ToolMode.craft:
        return 'C';
      case ToolMode.sell:
        return 'V';
      case ToolMode.cargo:
        return 'L';
    }
  }
}
