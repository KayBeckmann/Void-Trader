import 'package:vt_core/vt_core.dart';

/// Verkaufspreise in Credits pro Einheit (Roadmap Phase 6: planetare
/// Wirtschaft). Nur tatsächlich handelbare Güter sind gelistet — Credits
/// selbst haben keinen Preis, sie sind das Ergebnis eines Verkaufs.
const Map<Resource, int> sellPrices = {
  Resource.stone: 1,
  Resource.ore: 3,
  Resource.component: 8,
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
