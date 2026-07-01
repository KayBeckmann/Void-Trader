import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:void_trader/l10n/app_localizations.dart';
import 'core/providers/game_state_provider.dart';
import 'features/base/ui/base_overview_screen.dart';
import 'features/fleet/ui/fleet_screen.dart';
import 'features/map/ui/galaxy_map_screen.dart';
import 'features/space/game/void_trader_game.dart';
import 'features/space/ui/docking_overlay.dart';
import 'features/space/ui/hud_overlay.dart';
import 'features/space/ui/jump_overlay.dart';
import 'features/space/ui/mini_map.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_theme.dart';

class VoidTraderApp extends StatelessWidget {
  const VoidTraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Void Trader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
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
      home: const _VoidTraderShell(),
    );
  }
}

class _VoidTraderShell extends StatefulWidget {
  const _VoidTraderShell();

  @override
  State<_VoidTraderShell> createState() => _VoidTraderShellState();
}

class _VoidTraderShellState extends State<_VoidTraderShell> {
  final VoidTraderGame _game = VoidTraderGame();
  final GameState _gameState = GameState();
  int _tab = 0;
  bool _showJump = false;
  bool _showDocking = false;

  @override
  void initState() {
    super.initState();
    _game.onDockRequested = () => setState(() => _showDocking = true);
    _game.onJumpRequested = () => setState(() => _showJump = true);
    _game.onHudUpdate = () { if (mounted) setState(() {}); };
    _game.onSystemLoaded = (sys) async {
      await _gameState.enterSystem(sys);
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    final sys = _game.currentSystem;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content — IndexedStack keeps all tabs alive
          IndexedStack(
            index: _tab,
            children: [
              _HudTab(
                game: _game,
                gameState: _gameState,
                showJump: _showJump,
                showDocking: _showDocking,
                sys: sys,
                onJumpConfirm: _handleJump,
                onDismiss: _dismissOverlay,
                onFoundBase: () {
                  if (_game.pendingDock != null) {
                    _gameState.foundBase(_game.pendingDock!);
                  }
                  setState(() {});
                },
              ),
              const GalaxyMapScreen(),
              _BaseTab(gameState: _gameState),
              const FleetScreen(),
            ],
          ),

          // Bottom nav always on top
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _VoidNavBar(
              selectedIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
          ),
        ],
      ),
    );
  }

  void _handleJump() => _dismissOverlay();

  void _dismissOverlay() {
    setState(() {
      _showJump = false;
      _showDocking = false;
      _game.pendingJump = null;
      _game.pendingDock = null;
    });
  }
}

// ── HUD Tab ──────────────────────────────────────────────────────────────────

class _HudTab extends StatelessWidget {
  final VoidTraderGame game;
  final GameState gameState;
  final bool showJump;
  final bool showDocking;
  final dynamic sys;
  final VoidCallback onJumpConfirm;
  final VoidCallback onDismiss;
  final VoidCallback onFoundBase;

  const _HudTab({
    required this.game,
    required this.gameState,
    required this.showJump,
    required this.showDocking,
    required this.sys,
    required this.onJumpConfirm,
    required this.onDismiss,
    required this.onFoundBase,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget<VoidTraderGame>(game: game),

        if (!showJump && !showDocking && sys != null)
          HudOverlay(stats: game.playerStats, systemName: sys.name),

        if (!showJump && !showDocking)
          Positioned(
            top: 16,
            right: 16,
            child: ValueListenableBuilder<Vector2>(
              valueListenable: game.playerPosition,
              builder: (context, pos, _) {
                if (sys == null) return const SizedBox.shrink();
                return MiniMap(system: sys, playerPosition: pos);
              },
            ),
          ),

        if (showJump && game.pendingJump != null)
          JumpOverlay(
            targetSystem: game.pendingJump!.targetSystemId,
            onConfirm: onJumpConfirm,
            onCancel: onDismiss,
          ),

        if (showDocking && game.pendingDock != null)
          DockingOverlay(
            planet: game.pendingDock!,
            onUndock: onDismiss,
            market: gameState.currentMarket,
            player: gameState.player,
            base: gameState.base,
            onFoundBase: onFoundBase,
          ),
      ],
    );
  }
}

// ── Base Tab ─────────────────────────────────────────────────────────────────

class _BaseTab extends StatelessWidget {
  final GameState gameState;
  const _BaseTab({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final base = gameState.base;
    if (base == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hub_outlined, size: 64, color: AppColors.outline),
              const SizedBox(height: 16),
              Text(
                'KEINE BASIS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scanne einen Planeten, um eine Basis zu gründen.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return BaseOverviewScreen(
      base: base,
      playerInventory: gameState.player.inventory,
      playerCredits: gameState.player.credits,
      onCreditsChanged: () {},
      onClose: () {},
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────

class _VoidNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _VoidNavBar({required this.selectedIndex, required this.onTap});

  static const _items = [
    (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'HUD'),
    (icon: Icons.map_outlined, activeIcon: Icons.map, label: 'MAP'),
    (icon: Icons.hub_outlined, activeIcon: Icons.hub, label: 'BASE'),
    (icon: Icons.memory_outlined, activeIcon: Icons.memory, label: 'FLEET'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.90),
            border: Border(
              top: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = selectedIndex == i;
              return _NavItem(
                icon: active ? item.activeIcon : item.icon,
                label: item.label,
                active: active,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: active
            ? BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.30),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.primary : AppColors.outline.withValues(alpha: 0.70),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: active
                        ? AppColors.primary
                        : AppColors.outline.withValues(alpha: 0.70),
                    letterSpacing: 0.12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
