import 'package:flutter/material.dart';

import '../tool_mode.dart';
import 'hud_panel.dart';

/// Sichtbare, klickbare Werkzeugleiste (Roadmap UI-04) — löst dieselbe
/// Aktion aus wie die entsprechende Taste: ein Tap setzt [ToolMode], genau
/// wie [VoidTraderGame]'s Tastatur-Handler es für die Ziffern-/Buchstaben-
/// Shortcuts tut. Der aktive Modus wird farblich hervorgehoben, damit der
/// Spieler jederzeit sieht, was ein Klick auf die Karte gerade auslöst.
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
        spacing: 6,
        runSpacing: 6,
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
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE0A030) : const Color(0x40FFFFFF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            mode.label,
            style: TextStyle(
              color: active ? Colors.black : Colors.white,
              fontSize: 13,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
