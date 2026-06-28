import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:void_trader/l10n/app_localizations.dart';
import 'core/providers/game_state_provider.dart';
import 'features/space/game/void_trader_game.dart';
import 'features/space/ui/docking_overlay.dart';
import 'features/space/ui/hud_overlay.dart';
import 'features/space/ui/jump_overlay.dart';
import 'features/space/ui/mini_map.dart';

class VoidTraderApp extends StatelessWidget {
  const VoidTraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Void Trader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
      ],
      home: const _SpaceScreen(),
    );
  }
}

class _SpaceScreen extends StatefulWidget {
  const _SpaceScreen();

  @override
  State<_SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<_SpaceScreen> {
  final VoidTraderGame _game = VoidTraderGame();
  final GameState _gameState = GameState();
  bool _showJump = false;
  bool _showDocking = false;
  int _hudTick = 0;

  @override
  void initState() {
    super.initState();
    _game.onDockRequested = () => setState(() => _showDocking = true);
    _game.onJumpRequested = () => setState(() => _showJump = true);
    _game.onHudUpdate = () {
      if (mounted) setState(() => _hudTick++);
    };
    _game.onSystemLoaded = (sys) async {
      await _gameState.enterSystem(sys);
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    final sys = _game.currentSystem;
    return Scaffold(
      body: Stack(
        children: [
          GameWidget<VoidTraderGame>(game: _game),

          // HUD oben links
          if (!_showJump && !_showDocking && sys != null)
            HudOverlay(stats: _game.playerStats, systemName: sys.name),

          // Mini-Map oben rechts
          if (!_showJump && !_showDocking)
            Positioned(
              top: 16,
              right: 16,
              child: ValueListenableBuilder<Vector2>(
                valueListenable: _game.playerPosition,
                builder: (context, pos, child) {
                  if (sys == null) return const SizedBox.shrink();
                  return MiniMap(system: sys, playerPosition: pos);
                },
              ),
            ),

          // HUD hint unten rechts
          if (!_showJump && !_showDocking)
            const Positioned(
              bottom: 16,
              right: 16,
              child: _HudHint(),
            ),

          // Overlays
          if (_showJump && _game.pendingJump != null)
            JumpOverlay(
              targetSystem: _game.pendingJump!.targetSystemId,
              onConfirm: _handleJump,
              onCancel: _dismissOverlay,
            ),
          if (_showDocking && _game.pendingDock != null)
            DockingOverlay(
              planet: _game.pendingDock!,
              onUndock: _dismissOverlay,
              market: _gameState.currentMarket,
              player: _gameState.player,
            ),
        ],
      ),
    );
  }

  void _handleJump() {
    // TODO M2: system transition
    _dismissOverlay();
  }

  void _dismissOverlay() {
    setState(() {
      _showJump = false;
      _showDocking = false;
      _game.pendingJump = null;
      _game.pendingDock = null;
    });
  }
}

class _HudHint extends StatelessWidget {
  const _HudHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'WASD / ☞  Joystick — Nähern → F  — Space → Feuer',
        style: TextStyle(color: Colors.white54, fontSize: 11),
      ),
    );
  }
}
