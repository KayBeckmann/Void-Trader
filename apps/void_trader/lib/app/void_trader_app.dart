import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/void_trader_game.dart';
import '../ui/game_hud.dart';

class VoidTraderApp extends StatelessWidget {
  VoidTraderApp({super.key});

  // Bewusst als Instanzfeld statt in build() erzeugt: build() kann mehrfach
  // laufen (z.B. bei Theme-Änderungen) — ein neues VoidTraderGame() pro
  // Rebuild würde den Spielstand jedes Mal zurücksetzen.
  final VoidTraderGame game = VoidTraderGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Void Trader',
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: GameWidget(
          game: game,
          overlayBuilderMap: {
            'hud': (context, _) => GameHud(game: game),
          },
          initialActiveOverlays: const ['hud'],
        ),
      ),
    );
  }
}
