import 'package:flutter/foundation.dart';
import '../domain/market.dart';
import '../domain/player_state.dart';
import '../domain/star_system.dart';
import '../data/commodity_repository.dart';

class GameState extends ChangeNotifier {
  final PlayerState player = PlayerState(credits: 5000, cargoCapacity: 50);

  StarSystem? _currentSystem;
  SystemMarket? _currentMarket;

  StarSystem? get currentSystem => _currentSystem;
  SystemMarket? get currentMarket => _currentMarket;

  Future<void> enterSystem(StarSystem system) async {
    _currentSystem = system;
    _currentMarket = await CommodityRepository.generateMarket(system);
    notifyListeners();
  }

  void tickMarket(double dt) {
    _currentMarket?.simulateUpdate(dt);
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
