import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/space/game/void_trader_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: _GameApp(),
    ),
  );
}

class _GameApp extends StatelessWidget {
  const _GameApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Void Trader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: GameWidget(game: VoidTraderGame()),
    );
  }
}
