import 'package:flutter/material.dart';

import '../design_tokens.dart';
import 'hud_panel.dart';

/// Rückmeldung zur letzten Spieleraktion (Roadmap UI-06: "jede
/// Spieleraktion gibt eine kurze Meldung"; seit HUD-15 optisch an das
/// Scanner-Design von [InspectorPanel] angeglichen statt ein eigenständig
/// aussehendes Element zu sein). Zeigt nichts an, solange noch keine
/// Aktion stattgefunden hat — kein leeres Panel, das nur Platz wegnimmt.
class FeedbackToast extends StatelessWidget {
  final String? message;

  const FeedbackToast({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return HudPanel(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none, color: VtColors.accentCyan, size: 15),
          const SizedBox(width: VtSpacing.xs),
          Flexible(
            child: Text(text, style: const TextStyle(color: VtColors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
