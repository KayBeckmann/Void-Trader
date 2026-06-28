import 'dart:math' as math;
import 'building.dart';
import 'commodity.dart';
import 'crew.dart';

class ResourceNode {
  final String id;
  final String commodityId;
  final int gridX;
  final int gridY;
  const ResourceNode({
    required this.id,
    required this.commodityId,
    required this.gridX,
    required this.gridY,
  });
}

class MarauderEvent {
  final int strength; // 1–5
  final int turretCount;
  bool resolved = false;

  MarauderEvent({required this.strength, required this.turretCount});

  // Returns hull damage taken if turrets don't stop all attackers
  double resolve() {
    final stopped = (turretCount * 1.5).floor();
    final breached = (strength - stopped).clamp(0, strength);
    resolved = true;
    return breached * 15.0; // 15 hull damage per breached unit
  }
}

class BaseState {
  static const int gridWidth = 12;
  static const int gridHeight = 10;

  final String planetId;
  final String planetName;

  // Grid: null = leer, non-null = PlacedBuilding instanceId
  final List<List<String?>> _grid =
      List.generate(gridHeight, (_) => List.filled(gridWidth, null));

  final List<PlacedBuilding> buildings = [];
  final List<ResourceNode> resourceNodes = [];
  final List<CrewMember> crew = [];
  final Map<String, double> stockpile = {}; // commodityId → amount

  double storageCapacity = 200; // base capacity
  double dayTimer = 0;          // seconds
  double productionTimer = 0;   // seconds
  int dayCount = 0;
  bool isNight = false;

  double hullIntegrity = 100; // base hull (0 = destroyed)

  BaseState({required this.planetId, required this.planetName}) {
    _generateResourceNodes();
  }

  // ── Energy ──────────────────────────────────────────────────────────────
  double get energyProduced =>
      buildings.where((b) => b.isActive).fold(0.0, (s, b) => s + b.def.energyBalance.clamp(0, double.infinity));

  double get energyConsumed =>
      buildings.where((b) => b.isActive).fold(0.0, (s, b) => s + (-b.def.energyBalance).clamp(0, double.infinity));

  double get energyBalance => energyProduced - energyConsumed;

  // ── Grid helpers ─────────────────────────────────────────────────────────
  bool canPlace(BuildingDef def, int gx, int gy) {
    for (var dx = 0; dx < def.gridSize; dx++) {
      for (var dy = 0; dy < def.gridSize; dy++) {
        final x = gx + dx;
        final y = gy + dy;
        if (x >= gridWidth || y >= gridHeight) return false;
        if (_grid[y][x] != null) return false;
      }
    }
    return true;
  }

  PlacedBuilding? buildingAt(int gx, int gy) {
    final id = _grid[gy][gx];
    if (id == null) return null;
    try {
      return buildings.firstWhere((b) => b.instanceId == id);
    } catch (_) {
      return null;
    }
  }

  bool placeBuilding(BuildingDef def, int gx, int gy, Inventory playerInventory) {
    if (!canPlace(def, gx, gy)) return false;
    // Check build cost
    for (final cost in def.buildCost) {
      if (playerInventory.quantityOf(cost.commodityId) < cost.quantity) return false;
    }
    // Deduct materials
    for (final cost in def.buildCost) {
      playerInventory.remove(cost.commodityId, cost.quantity);
    }

    final instanceId = '${def.id}_${DateTime.now().microsecondsSinceEpoch}';
    final placed = PlacedBuilding(
      instanceId: instanceId,
      def: def,
      gridX: gx,
      gridY: gy,
    );
    buildings.add(placed);

    for (var dx = 0; dx < def.gridSize; dx++) {
      for (var dy = 0; dy < def.gridSize; dy++) {
        _grid[gy + dy][gx + dx] = instanceId;
      }
    }

    if (def.category == BuildingCategory.storage) {
      storageCapacity += 500;
    }

    _rebalanceEnergy();
    return true;
  }

  void removeBuilding(String instanceId) {
    final b = buildings.firstWhere((b) => b.instanceId == instanceId, orElse: () => throw StateError('not found'));
    for (var dy = 0; dy < b.def.gridSize; dy++) {
      for (var dx = 0; dx < b.def.gridSize; dx++) {
        _grid[b.gridY + dy][b.gridX + dx] = null;
      }
    }
    buildings.remove(b);
    if (b.def.category == BuildingCategory.storage) storageCapacity -= 500;
    _rebalanceEnergy();
  }

  void _rebalanceEnergy() {
    // Disable consumers if energy deficit, re-enable when enough
    var balance = energyProduced;
    // First pass: enable all producers, disable all consumers
    for (final b in buildings) {
      b.isActive = b.def.energyBalance > 0;
      if (b.isActive) balance += b.def.energyBalance;
    }
    // Second pass: enable consumers in order of placement
    for (final b in buildings) {
      if (b.def.energyBalance >= 0) continue;
      final cost = -b.def.energyBalance;
      if (balance >= cost) {
        b.isActive = true;
        balance -= cost;
      } else {
        b.isActive = false;
      }
    }
  }

  // ── Crew ─────────────────────────────────────────────────────────────────
  void hireCrew(CrewRole role) {
    crew.add(CrewMember.hire(role, crew.length));
  }

  bool assignCrew(String crewId, String buildingId) {
    final member = crew.where((c) => c.id == crewId).firstOrNull;
    if (member == null) return false;
    member.assignedBuildingId = buildingId;
    final b = buildings.where((b) => b.instanceId == buildingId).firstOrNull;
    if (b != null) b.assignedCrew++;
    return true;
  }

  double get dailyWageCost => crew.fold(0.0, (s, c) => s + c.dailyWage);

  // ── Production tick ───────────────────────────────────────────────────────
  void update(double dt) {
    productionTimer += dt;
    if (productionTimer >= 60) { // every real minute = production tick
      productionTimer = 0;
      _runProductionTick();
    }

    dayTimer += dt;
    if (dayTimer >= 300) { // 5 min real = 1 game day
      dayTimer = 0;
      dayCount++;
      isNight = !isNight;
      _runDayTick();
    }
  }

  void _runProductionTick() {
    final used = stockpile.values.fold(0.0, (s, v) => s + v);
    for (final b in buildings) {
      if (!b.isActive || b.def.outputs.isEmpty) continue;
      for (final output in b.def.outputs) {
        final amount = output.amountPerMinute * b.crewBonus;
        if (used + amount <= storageCapacity) {
          stockpile.update(output.commodityId, (v) => v + amount, ifAbsent: () => amount);
        }
      }
    }
  }

  void _runDayTick() {
    // Wage deduction handled by GameState to reduce PlayerState.credits
    // Marauder event: random at night
    if (isNight) {
      final rng = math.Random();
      if (rng.nextDouble() < 0.12) {
        _triggerMarauder(rng);
      }
    }
  }

  void _triggerMarauder(math.Random rng) {
    final turrets = buildings.where((b) => b.def.category == BuildingCategory.defense && b.isActive).length;
    final strength = 1 + rng.nextInt(4);
    final event = MarauderEvent(strength: strength, turretCount: turrets);
    final damage = event.resolve();
    hullIntegrity = (hullIntegrity - damage).clamp(0, 100);
  }

  // ── Resource node generation ──────────────────────────────────────────────
  void _generateResourceNodes() {
    final rng = math.Random(planetId.hashCode);
    final types = ['ore_iron', 'ore_iron', 'ore_ice', 'ore_organic'];
    for (var i = 0; i < 4; i++) {
      final x = 1 + rng.nextInt(gridWidth - 2);
      final y = 1 + rng.nextInt(gridHeight - 2);
      resourceNodes.add(ResourceNode(
        id: 'node_$i',
        commodityId: types[rng.nextInt(types.length)],
        gridX: x,
        gridY: y,
      ));
    }
  }

  String? cellAt(int gx, int gy) => _grid[gy][gx];
}
