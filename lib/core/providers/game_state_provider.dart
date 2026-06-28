import 'package:flutter/foundation.dart';
import '../domain/base_state.dart';
import '../domain/market.dart';
import '../domain/player_state.dart';
import '../domain/star_system.dart';
import '../data/commodity_repository.dart';

class GameState extends ChangeNotifier {
  final PlayerState player = PlayerState(credits: 5000, cargoCapacity: 50);

  StarSystem? _currentSystem;
  SystemMarket? _currentMarket;
  BaseState? _base;

  StarSystem? get currentSystem => _currentSystem;
  SystemMarket? get currentMarket => _currentMarket;
  BaseState? get base => _base;
  bool get hasBase => _base != null;

  Future<void> enterSystem(StarSystem system) async {
    _currentSystem = system;
    _currentMarket = await CommodityRepository.generateMarket(system);
    notifyListeners();
  }

  void foundBase(Planet planet) {
    if (_base != null) return;
    if (player.credits < 500) return;
    player.credits -= 500;
    _base = BaseState(planetId: planet.id, planetName: planet.name);
    notifyListeners();
  }

  void tickGame(double dt) {
    _currentMarket?.simulateUpdate(dt);
    if (_base != null) {
      final prevDay = _base!.dayCount;
      _base!.update(dt);
      if (_base!.dayCount != prevDay) {
        // Deduct daily crew wages
        player.credits -= _base!.dailyWageCost;
        if (player.credits < 0) player.credits = 0;
      }
      notifyListeners();
    }
  }

  void spend(double amount) {
    player.credits -= amount;
    notifyListeners();
  }

  void earn(double amount) {
    player.credits += amount;
    notifyListeners();
  }

  void notifyTradeComplete() => notifyListeners();
}
