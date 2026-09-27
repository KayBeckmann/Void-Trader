import 'package:vt_core/vt_core.dart';

/// Verkaufspreise in Credits pro Einheit (Roadmap Phase 6: planetare
/// Wirtschaft). Nur tatsächlich handelbare Güter sind gelistet — Credits
/// selbst haben keinen Preis, sie sind das Ergebnis eines Verkaufs.
const Map<Resource, int> sellPrices = {
  Resource.stone: 1,
  Resource.ore: 3,
  Resource.wood: 1,
  Resource.component: 8,
};

/// Verkaufspreise an einer Handelsstation im All (Roadmap Phase 9 V4:
/// "Eigene Stationspreise") — bewusst höher als [sellPrices], damit
/// Fracht ins All zu bringen eine lohnende Entscheidung ist, nicht nur
/// eine beliebige zweite Verkaufsstelle zu denselben Preisen. Enthält
/// dieselben Ressourcen wie [sellPrices] (V1: eine feste Aufschlag-
/// Preisliste statt schwankender/individueller Preise je Station).
const Map<Resource, int> stationSellPrices = {
  Resource.stone: 2,
  Resource.ore: 5,
  Resource.wood: 2,
  Resource.component: 12,
};

/// Ankaufpreise an einer Handelsstation im All (Roadmap Phase 9 V8:
/// "Ankauf an der Station") — bewusst deutlich über [stationSellPrices],
/// damit Kaufen-und-sofort-Zurückverkaufen an derselben Station kein
/// risikoloser Gewinn ist. Der eigentliche Sinn ist, Fracht dorthin zu
/// bringen, wo sie gebraucht wird (Bauteile für die Kolonie), nicht ein
/// Arbitragegeschäft.
///
/// Enthält seit Roadmap Phase 9 V9 ("Treibstoffverbrauch") zusätzlich
/// [Resource.fuel] — bewusst NICHT in [stationSellPrices]/[sellPrices]
/// gespiegelt: Treibstoff ist reines Verbrauchsgut fürs Schiff, nicht
/// Handelsware, die man auch verkaufen könnte (siehe [Resource.fuel]-Doc).
const Map<Resource, int> stationBuyPrices = {
  Resource.stone: 4,
  Resource.ore: 9,
  Resource.wood: 4,
  Resource.component: 20,
  Resource.fuel: 2,
};

/// Feste Einkaufsmenge je Ressource für "Vorräte kaufen" (Roadmap Phase 9
/// V8, seit V9 inkl. Treibstoff) — bewusst ein einziges Bündel statt einer
/// Mengenauswahl-UI, analog zum "gesamte Fracht verkaufen"-Knopf aus V3:
/// eine klare Aktion statt eines eigenen Shopping-Menüs. Die
/// Treibstoffmenge (30) liegt knapp unter [Ship.startingFuel] (40) — ein
/// einzelner Einkauf füllt den Tank spürbar auf, ohne ihn allein schon auf
/// Dauer unerschöpflich zu machen.
const Map<Resource, int> stationBuyBundle = {
  Resource.stone: 5,
  Resource.ore: 5,
  Resource.wood: 5,
  Resource.component: 2,
  Resource.fuel: 30,
};

/// Verkauft [amount] von [resource] aus [inventory] zum hinterlegten
/// Marktpreis (siehe [sellPrices]) und legt den Erlös als [Resource.credits]
/// ins selbe Inventar.
///
/// Gibt die erzielten Credits zurück, oder `null`, wenn [resource] nicht
/// handelbar ist oder nicht genug davon vorhanden war — in beiden Fällen
/// bleibt [inventory] unverändert (kein Teilverkauf).
int? sellResource(Inventory inventory, Resource resource, int amount) {
  if (amount <= 0) return null;
  final price = sellPrices[resource];
  if (price == null) return null;
  if (!inventory.has(resource, amount)) return null;

  final earned = amount * price;
  inventory.craft({resource: amount}, Resource.credits, outputAmount: earned);
  return earned;
}
