import 'package:flutter/material.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';

import '../../game/void_trader_game.dart';
import '../design_tokens.dart';
import 'hud_panel.dart';

/// Kleines Bau-/Craft-Menü V1 (Roadmap UI-05): listet jeden [BuildingType]
/// mit Kosten und markiert, ob sie gerade leistbar sind. Ein Tap wählt den
/// Typ nur aus (setzt [VoidTraderGame.selectedBuildingType]) — platziert
/// wird weiterhin per Klick auf die Karte über [VoidTraderGame.
/// performActionAt], inklusive Bauvorschau im Inspector-Panel.
///
/// Nur sichtbar/sinnvoll, wenn [ToolMode.build] aktiv ist — das entscheidet
/// [GameHud], nicht dieses Widget selbst.
class BuildMenu extends StatelessWidget {
  final BuildingType? selected;
  final Map<Resource, int> inventory;
  final ValueChanged<BuildingType> onSelect;

  const BuildMenu({
    super.key,
    required this.selected,
    required this.inventory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Baumenü',
            style: TextStyle(color: VtColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          for (final type in BuildingType.values)
            _BuildMenuEntry(
              type: type,
              active: type == selected,
              affordable: _canAfford(inventory, buildingDefinitionFor(type).buildCost),
              onTap: () => onSelect(type),
            ),
        ],
      ),
    );
  }

  static bool _canAfford(Map<Resource, int> inventory, Map<Resource, int> cost) {
    for (final entry in cost.entries) {
      if ((inventory[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }
}

class _BuildMenuEntry extends StatelessWidget {
  final BuildingType type;
  final bool active;
  final bool affordable;
  final VoidCallback onTap;

  const _BuildMenuEntry({
    required this.type,
    required this.active,
    required this.affordable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final definition = buildingDefinitionFor(type);
    final costText = definition.buildCost.entries
        .map((e) => '${VoidTraderGame.resourceLabel(e.key)} ${e.value}')
        .join(', ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VtRadii.button),
      child: Container(
        margin: const EdgeInsets.only(top: VtSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: VtSpacing.sm, vertical: VtSpacing.xs),
        decoration: BoxDecoration(
          color: active ? VtColors.accentAmber : const Color(0x30FFFFFF),
          borderRadius: BorderRadius.circular(VtRadii.button),
          border: Border.all(color: active ? VtColors.accentAmber : VtColors.panelBorder),
          boxShadow: active ? VtGlow.soft(VtColors.accentAmber) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              affordable ? Icons.check_circle_outline : Icons.block,
              color: affordable ? VtColors.accentGreen : VtColors.accentRed,
              size: 13,
            ),
            const SizedBox(width: VtSpacing.sm),
            Text(
              definition.name,
              style: TextStyle(
                color: active ? Colors.black : VtColors.textPrimary,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: VtSpacing.sm),
            Text(
              costText,
              style: TextStyle(
                color: active ? Colors.black87 : VtColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
