/// Sammelbare/verarbeitbare Rohstoffe (Roadmap Phase 4: Produktionskette).
///
/// Startet bewusst schmal mit dem, was aktuell tatsächlich gesammelt werden
/// kann (Abbau von Stein/Erz, siehe vt_world). Holz (Bäume fällen) und
/// Wasser (Fluid-Entnahme) kommen als eigene Interaktionen später dazu.
enum Resource {
  stone,
  ore,

  /// Verarbeitetes Bauteil (Roadmap Phase 4: Werkbank/Schmelzer-Ausgabe).
  /// Wird aus Rohstoffen gecraftet, nicht direkt in der Welt gesammelt.
  component,

  /// Zahlungsmittel (Roadmap Phase 6: planetare Wirtschaft). Entsteht durch
  /// Verkauf am Markt, wird nirgends direkt in der Welt gesammelt. Lebt
  /// bewusst im selben Inventar wie alle anderen Ressourcen statt in einer
  /// separaten "Wallet" — Verkaufen ist damit einfach eine weitere
  /// Umwandlung wie [Inventory.craft].
  credits,
}
