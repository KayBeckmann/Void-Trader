import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../objective.dart';
import 'hud_panel.dart';

/// Kleine Zielkette für den ersten Slice (Roadmap UI-07) — zeigt alle
/// [ObjectiveStatus] mit sichtbarer Erfüllung, bewusst kein Quest-System.
class ObjectivePanel extends StatelessWidget {
  final List<ObjectiveStatus> objectives;

  const ObjectivePanel({super.key, required this.objectives});

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Erste Schritte',
            style: TextStyle(color: VtColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          for (final objective in objectives)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    objective.isComplete ? Icons.check_box : Icons.check_box_outline_blank,
                    color: objective.isComplete ? VtColors.accentGreen : VtColors.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: VtSpacing.sm),
                  Flexible(
                    child: Text(
                      objective.description,
                      style: TextStyle(
                        color: objective.isComplete ? VtColors.textMuted : VtColors.textPrimary,
                        fontSize: 12,
                        decoration: objective.isComplete ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
