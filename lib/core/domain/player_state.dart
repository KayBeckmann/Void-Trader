import 'commodity.dart';
import 'market.dart';

class SmugglingResult {
  final bool scanned;
  final bool caught;
  final double fine;
  const SmugglingResult({required this.scanned, required this.caught, required this.fine});
}

class PlayerState {
  double credits;
  final Inventory inventory;
  final Map<String, int> _reputation; // faction → -100..100
  bool _cargoConcealed = false;

  PlayerState({
    this.credits = 5000,
    double cargoCapacity = 50,
  })  : inventory = Inventory(maxCapacity: cargoCapacity),
        _reputation = {
          'npc.consortium': 0,
          'npc.guild': 0,
          'npc.militia': 0,
          'npc.pirates': -20,
          'npc.research': 0,
          'npc.free': 10,
        };

  int reputationWith(String faction) => _reputation[faction] ?? 0;

  void adjustReputation(String faction, int delta) {
    _reputation[faction] = ((_reputation[faction] ?? 0) + delta).clamp(-100, 100);
  }

  bool get hasIllegalCargo =>
      inventory.slots.any((s) => s.commodity.isIllegal);

  void concealeIllegalCargo() => _cargoConcealed = true;
  void revealCargo() => _cargoConcealed = false;
  bool get cargoIsConcealed => _cargoConcealed;

  // Returns result of a scan event (called on docking or patrol encounter)
  SmugglingResult scanEvent(String systemFaction, double scanTech) {
    if (!hasIllegalCargo) return const SmugglingResult(scanned: true, caught: false, fine: 0);

    // Detection probability: base 60%, reduced by concealment, boosted by pirate faction
    var detectChance = 0.6 * scanTech;
    if (_cargoConcealed) detectChance *= 0.3;
    if (systemFaction == 'npc.pirates') detectChance = 0.0; // pirates don't care

    final caught = _catchRoll(detectChance);
    if (!caught) return const SmugglingResult(scanned: true, caught: false, fine: 0);

    // Fine: 3× value of illegal goods + rep penalty
    final fine = inventory.slots
        .where((s) => s.commodity.isIllegal)
        .fold(0.0, (sum, s) => sum + s.commodity.basePrice * s.quantity * 3);
    adjustReputation(systemFaction, -15);
    adjustReputation('npc.consortium', -5);

    // Confiscate illegal goods
    for (final s in inventory.slots.where((s) => s.commodity.isIllegal).toList()) {
      inventory.remove(s.commodity.id, s.quantity);
    }
    _cargoConcealed = false;

    return SmugglingResult(scanned: true, caught: true, fine: fine);
  }

  // Transaction helpers
  BuyResult buy(MarketListing listing, int quantity) {
    final price = listing.buyPrice() * quantity;
    if (credits < price) return BuyResult.insufficientCredits;
    if (!inventory.canAdd(listing.commodity, quantity)) return BuyResult.noCargoSpace;
    if (listing.stock < quantity) return BuyResult.outOfStock;

    credits -= price;
    listing.stock -= quantity;
    inventory.add(listing.commodity, quantity);
    return BuyResult.success;
  }

  SellResult sell(MarketListing listing, int quantity) {
    if (inventory.quantityOf(listing.commodity.id) < quantity) return SellResult.insufficientGoods;
    final price = listing.sellPrice() * quantity;
    inventory.remove(listing.commodity.id, quantity);
    listing.stock = (listing.stock + quantity).clamp(0, listing.maxStock);
    credits += price;
    return SellResult.success;
  }

  bool _catchRoll(double probability) {
    // Simple roll — replace with seeded RNG when save system is in
    final roll = DateTime.now().microsecondsSinceEpoch % 1000 / 1000.0;
    return roll < probability;
  }
}

enum BuyResult { success, insufficientCredits, noCargoSpace, outOfStock }
enum SellResult { success, insufficientGoods }
