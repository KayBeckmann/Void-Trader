enum CommodityCategory {
  raw,        // Rohstoffe
  industrial, // Industriegüter
  luxury,     // Luxuswaren
  illegal,    // Schmuggel
  research,   // Forschungsgüter
  consumable, // Verbrauchsgüter (Treibstoff, Nahrung, Munition)
}

class CommodityDef {
  final String id;
  final String name;
  final CommodityCategory category;
  final double basePrice;   // Credits pro Einheit
  final double volume;      // Laderaumeinheiten pro Stück
  final bool isIllegal;
  final bool isResearch;
  final String description;

  const CommodityDef({
    required this.id,
    required this.name,
    required this.category,
    required this.basePrice,
    required this.volume,
    required this.description,
    this.isIllegal = false,
    this.isResearch = false,
  });

  factory CommodityDef.fromJson(Map<String, dynamic> j) => CommodityDef(
        id: j['id'] as String,
        name: j['name'] as String,
        category: CommodityCategory.values.firstWhere(
          (c) => c.name == j['category'],
          orElse: () => CommodityCategory.raw,
        ),
        basePrice: (j['base_price'] as num).toDouble(),
        volume: (j['volume'] as num?)?.toDouble() ?? 1.0,
        description: j['description'] as String? ?? '',
        isIllegal: j['is_illegal'] as bool? ?? false,
        isResearch: j['is_research'] as bool? ?? false,
      );
}

class InventorySlot {
  final CommodityDef commodity;
  int quantity;

  InventorySlot({required this.commodity, required this.quantity});

  double get totalVolume => commodity.volume * quantity;
}

class Inventory {
  final double maxCapacity; // Laderaumeinheiten
  final Map<String, InventorySlot> _slots = {};

  Inventory({required this.maxCapacity});

  double get usedCapacity =>
      _slots.values.fold(0.0, (sum, s) => sum + s.totalVolume);
  double get freeCapacity => maxCapacity - usedCapacity;

  List<InventorySlot> get slots => _slots.values.toList();

  int quantityOf(String commodityId) => _slots[commodityId]?.quantity ?? 0;

  bool canAdd(CommodityDef commodity, int quantity) =>
      freeCapacity >= commodity.volume * quantity;

  bool add(CommodityDef commodity, int quantity) {
    if (!canAdd(commodity, quantity)) return false;
    _slots.update(
      commodity.id,
      (s) {
        s.quantity += quantity;
        return s;
      },
      ifAbsent: () => InventorySlot(commodity: commodity, quantity: quantity),
    );
    return true;
  }

  bool remove(String commodityId, int quantity) {
    final slot = _slots[commodityId];
    if (slot == null || slot.quantity < quantity) return false;
    slot.quantity -= quantity;
    if (slot.quantity == 0) _slots.remove(commodityId);
    return true;
  }
}
