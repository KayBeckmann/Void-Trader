import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../tile_inspector_info.dart';
import 'hud_panel.dart';

/// Zeigt, was am gerade ausgewählten/anvisierten Tile möglich ist — und
/// warum nicht, falls eine Aktion gesperrt ist (Roadmap UI-02/UI-03:
/// "Inspector zeigt verständliche deutsche Labels"; seit HUD-15 als
/// "Scanner"-/Analysepanel gestaltet: Kopfzeile mit Scan-Kennzeichnung,
/// Zustand und Aktionen sauber durch eine Trennlinie gruppiert statt
/// undifferenziert untereinander zu stehen).
class InspectorPanel extends StatelessWidget {
  final TileInspectorInfo info;

  const InspectorPanel({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 340),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radar, color: VtColors.accentCyan, size: 14),
                SizedBox(width: VtSpacing.xs),
                Text(
                  'SCAN',
                  style: TextStyle(
                    color: VtColors.accentCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              info.title,
              style: const TextStyle(
                color: VtColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (info.details.isNotEmpty) ...[
              const SizedBox(height: VtSpacing.xs),
              for (final detail in info.details)
                Text(detail, style: const TextStyle(color: VtColors.textSecondary, fontSize: 12)),
            ],
            if (info.actions.isNotEmpty) ...[
              const SizedBox(height: VtSpacing.sm),
              Container(height: 1, color: VtColors.panelBorder),
              const SizedBox(height: VtSpacing.xs),
              for (final action in info.actions) _ActionLine(action: action),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionLine extends StatelessWidget {
  final InspectorActionInfo action;

  const _ActionLine({required this.action});

  @override
  Widget build(BuildContext context) {
    final label = action.keyHint.isEmpty ? action.label : '${action.label} (${action.keyHint})';
    return Padding(
      padding: const EdgeInsets.only(top: VtSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            action.available ? Icons.check_circle_outline : Icons.block,
            color: action.available ? VtColors.accentGreen : VtColors.accentRed,
            size: 14,
          ),
          const SizedBox(width: VtSpacing.xs),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(color: VtColors.textPrimary, fontSize: 12),
                  ),
                  if (!action.available && action.blockedReason != null)
                    TextSpan(
                      text: ' — ${action.blockedReason}',
                      style: const TextStyle(color: VtColors.accentRed, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
