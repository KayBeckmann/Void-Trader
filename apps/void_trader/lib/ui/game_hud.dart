import 'package:flutter/material.dart';
import 'package:vt_core/vt_core.dart';

import '../game/void_trader_game.dart';

/// Flutter-HUD-Overlay für [VoidTraderGame] — echtes Interface statt
/// stummer Tastatursteuerung: Inventar, Tageszeit, ein Hinweis, was an der
/// aktuellen Position möglich ist, Rückmeldung zur letzten Aktion und eine
/// kompakte Steuerungs-Legende.
///
/// Rein informativ (kein eigener Touch-Input) — [IgnorePointer] sorgt
/// dafür, dass Klicks/Taps weiterhin beim darunterliegenden [GameWidget]
/// ankommen.
class GameHud extends StatelessWidget {
  final VoidTraderGame game;

  const GameHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InventoryPanel(game: game),
                  _StatusPanel(game: game),
                ],
              ),
              const Spacer(),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InteractionHint(game: game),
                  const SizedBox(height: 6),
                  _FeedbackBanner(game: game),
                  const SizedBox(height: 6),
                  const _ControlsLegend(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gemeinsame Optik für alle HUD-Kacheln.
class _HudPanel extends StatelessWidget {
  final Widget child;
  final Color color;

  const _HudPanel({required this.child, this.color = const Color(0xB0000000)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: child,
    );
  }
}

class _InventoryPanel extends StatelessWidget {
  final VoidTraderGame game;

  const _InventoryPanel({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.hudTick,
      builder: (context, _, _) => _HudPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final resource in Resource.values)
              Text(
                '${VoidTraderGame.resourceLabel(resource)}: ${game.inventory.count(resource)}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final VoidTraderGame game;

  const _StatusPanel({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.hudTick,
      builder: (context, _, _) {
        final cycle = game.dayNightCycle;
        final totalMinutes = (cycle.timeOfDay * 24 * 60).floor();
        final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
        final minutes = (totalMinutes % 60).toString().padLeft(2, '0');

        return _HudPanel(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                cycle.isDay ? Icons.wb_sunny : Icons.nightlight_round,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text('$hours:$minutes', style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}

class _InteractionHint extends StatelessWidget {
  final VoidTraderGame game;

  const _InteractionHint({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.hudTick,
      builder: (context, _, _) {
        final hint = game.currentInteractionHint();
        if (hint == null) return const SizedBox.shrink();
        return _HudPanel(
          child: Text(
            hint,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final VoidTraderGame game;

  const _FeedbackBanner({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: game.feedbackMessage,
      builder: (context, message, _) {
        if (message == null) return const SizedBox.shrink();
        return _HudPanel(
          child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13)),
        );
      },
    );
  }
}

class _ControlsLegend extends StatelessWidget {
  const _ControlsLegend();

  @override
  Widget build(BuildContext context) {
    return const _HudPanel(
      color: Color(0x80000000),
      child: Text(
        'WASD/Pfeile Bewegen · Leertaste/E Graben · 1-4 Bauen · '
        'C Craften · V Verkaufen · L Fracht laden · F1 Debug-Ansicht',
        style: TextStyle(color: Colors.white70, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}
