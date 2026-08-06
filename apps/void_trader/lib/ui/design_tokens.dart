import 'package:flutter/material.dart';

/// Zentrale visuelle Grundwerte für das Space-HUD (Roadmap-Sofort-Korrektur
/// "Fullscreen-Spieldesign, Minimap und Space-HUD-Polish", HUD-10:
/// "Space-Design-Tokens") — ein Ort für Farben/Radien/Abstände statt
/// verstreuter Magic Colors in jedem Widget. Alle HUD-Widgets sollen diese
/// Tokens nutzen statt eigene Farbwerte zu erfinden.
///
/// Stilrichtung laut Roadmap: "spacy / rugged sci-fi / colony operations",
/// dunkles Glas mit dezentem Glow statt generischer Flutter-Standardkarten.
abstract final class VtColors {
  /// Standard-Panelhintergrund — dunkles Glas mit leichtem Blaustich.
  static const Color panelBackground = Color(0xD40B1220);

  /// Etwas transparenterer Panelhintergrund für sekundäre/leisere Flächen
  /// (z.B. Steuerungslegende).
  static const Color panelBackgroundSubtle = Color(0x9E0B1220);

  /// Dezenter Rand um Panels — hebt sie vom Hintergrund ab, ohne laut zu
  /// wirken.
  static const Color panelBorder = Color(0x4D5FD1FF);

  /// Primäre Akzentfarbe (Cyan) — Hologramm-/Scanner-Optik, Standard für
  /// interaktive Ränder/Icons ohne besondere Bedeutung.
  static const Color accentCyan = Color(0xFF5FD1FF);

  /// Aktiv-/Auswahl-Akzent (Amber) — "das hier ist gerade ausgewählt/
  /// aktiv" (z.B. aktives Toolbelt-Werkzeug).
  static const Color accentAmber = Color(0xFFE0A030);

  /// Positiv-/Erfolgs-Akzent (Grün) — verfügbare Aktionen, erfüllte Ziele.
  static const Color accentGreen = Color(0xFF6FE08A);

  /// Warn-/Sperr-Akzent (Rot) — nicht verfügbare Aktionen, Blockaden.
  static const Color accentRed = Color(0xFFFF6B6B);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;
}

abstract final class VtRadii {
  static const double panel = 10;
  static const double chip = 8;
  static const double button = 8;
}

abstract final class VtSpacing {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
}

/// Dezenter Leucht-/Glow-Rand für aktive/hervorgehobene Elemente — löst
/// "feine Linien, Ecken, kleine Statuspunkte, dezente Glow-Ränder" aus der
/// Roadmap-Designrichtung ohne Bedienbarkeit zu verschlechtern.
abstract final class VtGlow {
  static List<BoxShadow> soft(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10, spreadRadius: 0.5),
  ];
}
