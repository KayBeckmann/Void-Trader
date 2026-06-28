import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../domain/commodity.dart';
import '../domain/market.dart';
import '../domain/star_system.dart';

class CommodityRepository {
  static List<CommodityDef>? _cache;

  static Future<List<CommodityDef>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/commodities.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (json['commodities'] as List<dynamic>)
        .map((c) => CommodityDef.fromJson(c as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  // Generate a market for a system based on its tier and planet types
  static Future<SystemMarket> generateMarket(StarSystem system) async {
    final all = await loadAll();
    final rng = math.Random(system.id.hashCode);
    final planetTypes = system.planets.map((p) => p.type).toSet();

    final listings = <MarketListing>[];

    for (final commodity in all) {
      if (!_isAvailable(commodity, system, planetTypes)) continue;

      final (producer, consumer) = _roleFor(commodity, planetTypes, rng);
      final demand = 0.5 + rng.nextDouble() * 1.0;
      final supply = 0.5 + rng.nextDouble() * 1.0;
      final maxStock = producer ? 100 + rng.nextInt(150) : 10 + rng.nextInt(60);

      listings.add(MarketListing(
        commodity: commodity,
        stock: (maxStock * (0.3 + rng.nextDouble() * 0.5)).round(),
        maxStock: maxStock,
        demandFactor: consumer ? demand * 1.4 : demand,
        supplyFactor: producer ? supply * 1.4 : supply,
        isProducer: producer,
        isConsumer: consumer,
      ));
    }

    return SystemMarket(systemId: system.id, listings: listings);
  }

  static bool _isAvailable(
      CommodityDef c, StarSystem system, Set<String> planetTypes) {
    // Illegal goods not available in core systems (except pirate-tier)
    if (c.isIllegal && system.tier == SystemTier.core) {
      if (system.ownerFaction != 'npc.pirates') return false;
    }
    // Research goods require research stations
    if (c.isResearch && !planetTypes.contains('habitat')) return false;
    // Alien tech only in outer/pirate systems
    if (c.id == 'res_alien_tech' && system.tier == SystemTier.core) return false;
    return true;
  }

  static (bool producer, bool consumer) _roleFor(
      CommodityDef c, Set<String> types, math.Random rng) {
    return switch (c.category) {
      CommodityCategory.raw => (types.contains('mining'), types.contains('industrial')),
      CommodityCategory.industrial => (types.contains('industrial'), types.contains('trade')),
      CommodityCategory.luxury => (false, rng.nextBool()),
      CommodityCategory.illegal => (rng.nextBool(), rng.nextBool()),
      CommodityCategory.research => (types.contains('habitat'), false),
      CommodityCategory.consumable => (types.contains('industrial'), true),
    };
  }
}
