import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../tool_mode.dart';
import 'hud_panel.dart';

/// Sichtbare, klickbare Werkzeugleiste (Roadmap UI-04, seit HUD-14 mit
/// Icons + Leucht-Rahmen für den aktiven Modus statt reiner Textbuttons) —
/// löst dieselbe Aktion aus wie die entsprechende Taste: ein Tap setzt
/// [ToolMode], genau wie [VoidTraderGame]'s Tastatur-Handler es für die
/// Ziffern-/Buchstaben-Shortcuts tut.
///
/// Bewusst NICHT von [IgnorePointer] umschlossen — anders als die reinen
/// Info-Panels (Topbar/Ressourcen/Inspector) muss dieses Panel echten
/// Touch-/Maus-Input empfangen.
class ToolbeltPanel extends StatelessWidget {
  final ToolMode activeTool;
  final ValueChanged<ToolMode> onSelect;

  const ToolbeltPanel({super.key, required this.activeTool, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      // Wrap statt Row: auf schmalen Bildschirmen/Testviewports brechen die
      // sechs Modus-Buttons in eine zweite Zeile um, statt einen
      // RenderFlex-Overflow zu erzeugen.
      child: Wrap(
        spacing: VtSpacing.sm,
        runSpacing: VtSpacing.sm,
        alignment: WrapAlignment.center,
        children: [
          for (final mode in ToolMode.values)
            _ToolButton(mode: mode, active: mode == activeTool, onTap: () => onSelect(mode)),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final ToolMode mode;
  final bool active;
  final VoidCallback onTap;

  const _ToolButton({required this.mode, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = mode.keyHint.isEmpty ? mode.label : '${mode.label} (${mode.keyHint})';
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VtRadii.button),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: VtSpacing.md, vertical: VtSpacing.sm),
          decoration: BoxDecoration(
            color: active ? VtColors.accentAmber : const Color(0x40FFFFFF),
            borderRadius: BorderRadius.circular(VtRadii.button),
            border: Border.all(color: active ? VtColors.accentAmber : VtColors.panelBorder),
            boxShadow: active ? VtGlow.soft(VtColors.accentAmber) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(mode), color: active ? Colors.black : VtColors.textPrimary, size: 18),
              const SizedBox(height: 2),
              Text(
                mode.label,
                style: TextStyle(
                  color: active ? Colors.black : VtColors.textPrimary,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (mode.keyHint.isNotEmpty)
                Text(
                  mode.keyHint,
                  style: TextStyle(
                    color: active ? Colors.black87 : VtColors.textMuted,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(ToolMode mode) {
    switch (mode) {
      case ToolMode.inspect:
        return Icons.pan_tool_alt_outlined;
      case ToolMode.dig:
        return Icons.construction;
      case ToolMode.build:
        return Icons.foundation;
      case ToolMode.craft:
        return Icons.precision_manufacturing_outlined;
      case ToolMode.sell:
        return Icons.storefront_outlined;
      case ToolMode.cargo:
        return Icons.local_shipping_outlined;
    }
  }
}
