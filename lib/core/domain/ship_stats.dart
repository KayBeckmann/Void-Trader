class ShipStats {
  final double maxHull;
  final double maxShield;
  final double shieldRechargeRate; // per second
  final double shieldRechargeDelay; // seconds after taking damage

  double hull;
  double shield;
  double _shieldRechargeTimer = 0;

  ShipStats({
    required this.maxHull,
    required this.maxShield,
    required this.shieldRechargeRate,
    required this.shieldRechargeDelay,
  })  : hull = maxHull,
        shield = maxShield;

  bool get isAlive => hull > 0;
  double get hullPercent => hull / maxHull;
  double get shieldPercent => shield / maxShield;

  void update(double dt) {
    if (_shieldRechargeTimer > 0) {
      _shieldRechargeTimer -= dt;
    } else if (shield < maxShield) {
      shield = (shield + shieldRechargeRate * dt).clamp(0, maxShield);
    }
  }

  // Returns true if the ship is destroyed
  bool applyDamage(double amount) {
    _shieldRechargeTimer = shieldRechargeDelay;
    if (shield > 0) {
      final overflow = amount - shield;
      shield = (shield - amount).clamp(0, maxShield);
      if (overflow > 0) hull = (hull - overflow).clamp(0, maxHull);
    } else {
      hull = (hull - amount).clamp(0, maxHull);
    }
    return hull <= 0;
  }

  void repair(double amount) {
    hull = (hull + amount).clamp(0, maxHull);
  }

  static ShipStats playerDefault() => ShipStats(
        maxHull: 200,
        maxShield: 100,
        shieldRechargeRate: 12,
        shieldRechargeDelay: 4,
      );

  static ShipStats pirateBasic() => ShipStats(
        maxHull: 80,
        maxShield: 20,
        shieldRechargeRate: 5,
        shieldRechargeDelay: 6,
      );
}
