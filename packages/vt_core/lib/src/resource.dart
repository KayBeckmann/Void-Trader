/// Sammelbare/verarbeitbare Rohstoffe (Roadmap Phase 4: Produktionskette).
///
/// Startet bewusst schmal mit dem, was aktuell tatsächlich gesammelt werden
/// kann (Abbau von Stein/Erz, siehe vt_world). Wasser (Fluid-Entnahme) kommt
/// als eigene Interaktion später dazu.
enum Resource {
  stone,
  ore,

  /// Holz aus abgeholztem Wald (Roadmap: "Holz/Wald", Kays Feedback
  /// 2026-09-27). Baumaterial für Hütte/Zaun/Leiter und Zutat für
  /// Bauteile/Werkzeuge neben Stein/Erz — siehe `basicComponentRecipe` und
  /// die entsprechenden `BuildingDefinition`s in vt_content.
  wood,

  /// Verarbeitetes Bauteil (Roadmap Phase 4: Werkbank/Schmelzer-Ausgabe).
  /// Wird aus Rohstoffen gecraftet, nicht direkt in der Welt gesammelt.
  component,

  /// Zahlungsmittel (Roadmap Phase 6: planetare Wirtschaft). Entsteht durch
  /// Verkauf am Markt, wird nirgends direkt in der Welt gesammelt. Lebt
  /// bewusst im selben Inventar wie alle anderen Ressourcen statt in einer
  /// separaten "Wallet" — Verkaufen ist damit einfach eine weitere
  /// Umwandlung wie [Inventory.craft].
  credits,

  /// Schiffs-Treibstoff (Roadmap Phase 9, V9: "Treibstoffverbrauch").
  /// Bewusst nur an Handelsstationen käuflich (siehe
  /// `stationBuyPrices`/`stationBuyBundle` in vt_content), nicht auf dem
  /// Planeten abbaubar oder zurückverkaufbar — echte Förderung/Raffinerie
  /// sind ein späterer Schritt. Lebt ausschließlich im Schiffsfrachtraum
  /// ([Ship.cargo]), nicht im Spieler-Inventar — siehe
  /// `VoidTraderGame._isTransportableCargo`, das Treibstoff bewusst von
  /// `loadCargoAt`/`unloadCargoAt` ausnimmt.
  fuel,
}
