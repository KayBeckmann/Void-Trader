import 'dart:math' as math;
import 'commodity.dart';

enum MarketEventType { war, epidemic, blockade, boom, shortage }

class MarketEvent {
  final MarketEventType type;
  final String affectedCommodityId; // '' = alle
  final double priceMultiplier;     // z.B. 1.8 = +80 %
  final int durationDays;
  int remainingDays;

  MarketEvent({
    required this.type,
    required this.affectedCommodityId,
    required this.priceMultiplier,
    required this.durationDays,
  }) : remainingDays = durationDays;

  bool get isActive => remainingDays > 0;

  String get label => switch (type) {
        MarketEventType.war => 'Krieg',
        MarketEventType.epidemic => 'Epidemie',
        MarketEventType.blockade => 'Tor-Sperrung',
        MarketEventType.boom => 'Wirtschaftsboom',
        MarketEventType.shortage => 'Engpass',
      };
}

class MarketListing {
  final CommodityDef commodity;
  int stock;
  final int maxStock;
  final double demandFactor;  // 0–2 (1 = neutral)
  final double supplyFactor;  // 0–2 (1 = neutral)
  final bool isProducer;      // senkt Verkaufspreis
  final bool isConsumer;      // erhöht Kaufpreis

  MarketListing({
    required this.commodity,
    required this.stock,
    required this.maxStock,
    required this.demandFactor,
    required this.supplyFactor,
    required this.isProducer,
    required this.isConsumer,
  });

  double currentPrice({double eventMultiplier = 1.0}) {
    // Basisformel: basePrice * demand/supply * event
    final factor = (1.0 + demandFactor - supplyFactor).clamp(0.3, 3.5);
    return (commodity.basePrice * factor * eventMultiplier).roundToDouble();
  }

  double buyPrice({double eventMultiplier = 1.0}) =>
      currentPrice(eventMultiplier: eventMultiplier) * 1.05; // 5% Handelsmarge

  double sellPrice({double eventMultiplier = 1.0}) =>
      currentPrice(eventMultiplier: eventMultiplier) * 0.95;
}

class SystemMarket {
  final String systemId;
  final List<MarketListing> listings;
  final List<MarketEvent> events;
  double _dayTimer = 0;

  SystemMarket({
    required this.systemId,
    required this.listings,
    List<MarketEvent>? events,
  }) : events = events ?? [];

  // Returns combined price multiplier for a commodity
  double eventMultiplierFor(String commodityId) {
    var m = 1.0;
    for (final e in events) {
      if (!e.isActive) continue;
      if (e.affectedCommodityId.isEmpty || e.affectedCommodityId == commodityId) {
        m *= e.priceMultiplier;
      }
    }
    return m;
  }

  List<MarketEvent> get activeEvents => events.where((e) => e.isActive).toList();

  // Call once per game-day to simulate NPC trading + restock
  void tickDay(math.Random rng) {
    // Remove expired events
    events.removeWhere((e) {
      e.remainingDays--;
      return e.remainingDays <= 0;
    });

    // Restock producers, drain consumers
    for (final l in listings) {
      if (l.isProducer) {
        final restock = (l.maxStock * 0.15).round().clamp(1, l.maxStock);
        l.stock = (l.stock + restock).clamp(0, l.maxStock);
      }
      if (l.isConsumer) {
        final consume = (l.maxStock * 0.10).round().clamp(0, l.stock);
        l.stock = (l.stock - consume).clamp(0, l.maxStock);
      }
    }

    // Random event chance (2% per day per market)
    if (rng.nextDouble() < 0.02) {
      _spawnRandomEvent(rng);
    }
  }

  void simulateUpdate(double dt) {
    _dayTimer += dt;
    if (_dayTimer >= 120) { // 2 real minutes = 1 game day
      _dayTimer = 0;
      tickDay(math.Random());
    }
  }

  void _spawnRandomEvent(math.Random rng) {
    final types = MarketEventType.values;
    final type = types[rng.nextInt(types.length)];
    final listingIdx = rng.nextInt(listings.length);
    final commodityId = rng.nextBool() ? listings[listingIdx].commodity.id : '';
    final multiplier = type == MarketEventType.boom
        ? 0.7
        : type == MarketEventType.shortage
            ? 2.0
            : 1.4 + rng.nextDouble() * 0.8;

    events.add(MarketEvent(
      type: type,
      affectedCommodityId: commodityId,
      priceMultiplier: multiplier,
      durationDays: 3 + rng.nextInt(8),
    ));
  }
}
