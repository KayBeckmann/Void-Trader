import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/void_trader_game.dart';

class VoidTraderApp extends StatelessWidget {
  const VoidTraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Void Trader',
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: GameWidget(game: VoidTraderGame()),
      ),
    );
  }
}
