import 'package:flutter/material.dart';
import 'package:vt_core/vt_core.dart';

import '../../game/void_trader_game.dart';
import 'hud_panel.dart';

/// Inventar-Übersicht als eigenständiges Panel (Roadmap UI-02).
class ResourceBar extends StatelessWidget {
  final Map<Resource, int> inventory;

  const ResourceBar({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final resource in Resource.values)
            Text(
              '${VoidTraderGame.resourceLabel(resource)}: ${inventory[resource] ?? 0}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
        ],
      ),
    );
  }
}
