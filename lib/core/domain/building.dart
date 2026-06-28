enum BuildingCategory { energy, extraction, production, storage, defense, special }
enum BuildingTier { tier1, tier2, tier3 }

class ResourceOutput {
  final String commodityId;
  final double amountPerMinute;
  const ResourceOutput({required this.commodityId, required this.amountPerMinute});
}

class CraftingInput {
  final String commodityId;
  final int quantity;
  const CraftingInput({required this.commodityId, required this.quantity});
}

class BuildingDef {
  final String id;
  final String name;
  final BuildingCategory category;
  final BuildingTier tier;
  final double energyBalance;   // >0 = produces, <0 = consumes
  final int gridSize;           // 1 = 1×1, 2 = 2×2 tiles
  final List<CraftingInput> buildCost;
  final List<ResourceOutput> outputs;
  final String description;
  final bool isStub;            // nicht voll implementiert, sperrt UI

  const BuildingDef({
    required this.id,
    required this.name,
    required this.category,
    required this.tier,
    required this.energyBalance,
    required this.gridSize,
    required this.buildCost,
    required this.outputs,
    required this.description,
    this.isStub = false,
  });

  factory BuildingDef.fromJson(Map<String, dynamic> j) {
    return BuildingDef(
      id: j['id'] as String,
      name: j['name'] as String,
      category: BuildingCategory.values.firstWhere(
          (c) => c.name == j['category'], orElse: () => BuildingCategory.production),
      tier: BuildingTier.values.firstWhere(
          (t) => t.name == j['tier'], orElse: () => BuildingTier.tier1),
      energyBalance: (j['energy_balance'] as num).toDouble(),
      gridSize: j['grid_size'] as int? ?? 1,
      buildCost: (j['build_cost'] as List<dynamic>? ?? [])
          .map((c) => CraftingInput(
                commodityId: c['id'] as String,
                quantity: c['qty'] as int,
              ))
          .toList(),
      outputs: (j['outputs'] as List<dynamic>? ?? [])
          .map((o) => ResourceOutput(
                commodityId: o['id'] as String,
                amountPerMinute: (o['per_min'] as num).toDouble(),
              ))
          .toList(),
      description: j['description'] as String? ?? '',
      isStub: j['is_stub'] as bool? ?? false,
    );
  }
}

class PlacedBuilding {
  final String instanceId;
  final BuildingDef def;
  final int gridX;
  final int gridY;
  bool isActive;           // false wenn Energiemangel
  int assignedCrew;
  double productionBuffer; // akkumulierte Produktion (Minuten-Basis)

  PlacedBuilding({
    required this.instanceId,
    required this.def,
    required this.gridX,
    required this.gridY,
    this.isActive = true,
    this.assignedCrew = 0,
    this.productionBuffer = 0,
  });

  double get crewBonus => 1.0 + assignedCrew * 0.2; // +20% pro Crew
}
