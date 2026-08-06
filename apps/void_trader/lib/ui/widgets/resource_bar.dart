import 'package:flutter/material.dart';
import 'package:vt_core/vt_core.dart';

import '../../game/void_trader_game.dart';
import '../design_tokens.dart';

/// Inventar-Übersicht als kompakte Chip-Reihe statt Textliste (Roadmap
/// HUD-12: "ResourceBar V2") — jede Ressource ein eigenes Badge mit Icon,
/// Wert und Kürzel. Credits gehören bewusst nicht hierher — die zeigt
/// [TopStatusBar] prominent an (Roadmap HUD-11), diese Leiste bleibt auf
/// Rohstoffe/Bauteile fokussiert (siehe Roadmap-Gruppierung).
class ResourceBar extends StatelessWidget {
  final Map<Resource, int> inventory;

  const ResourceBar({super.key, required this.inventory});

  static const _displayedResources = [Resource.stone, Resource.ore, Resource.component];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: VtSpacing.sm,
      runSpacing: VtSpacing.sm,
      children: [
        for (final resource in _displayedResources)
          _ResourceChip(resource: resource, amount: inventory[resource] ?? 0),
      ],
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final Resource resource;
  final int amount;

  const _ResourceChip({required this.resource, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VtSpacing.md, vertical: VtSpacing.xs),
      decoration: BoxDecoration(
        color: VtColors.panelBackground,
        borderRadius: BorderRadius.circular(VtRadii.chip),
        border: Border.all(color: VtColors.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(resource), color: _colorFor(resource), size: 15),
          const SizedBox(width: VtSpacing.xs),
          Text(
            '$amount',
            style: const TextStyle(
              color: VtColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: VtSpacing.xs),
          Text(
            VoidTraderGame.resourceLabel(resource),
            style: const TextStyle(color: VtColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(Resource resource) {
    switch (resource) {
      case Resource.stone:
        return Icons.terrain;
      case Resource.ore:
        return Icons.diamond_outlined;
      case Resource.component:
        return Icons.settings_outlined;
      case Resource.credits:
        return Icons.paid_outlined;
    }
  }

  static Color _colorFor(Resource resource) {
    switch (resource) {
      case Resource.stone:
        return VtColors.textSecondary;
      case Resource.ore:
        return VtColors.accentAmber;
      case Resource.component:
        return VtColors.accentCyan;
      case Resource.credits:
        return VtColors.accentGreen;
    }
  }
}
