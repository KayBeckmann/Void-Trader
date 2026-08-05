import 'package:flutter/material.dart';

import 'hud_panel.dart';

/// Rückmeldung zur letzten Spieleraktion (Roadmap UI-06: "jede
/// Spieleraktion gibt eine kurze Meldung"). Zeigt nichts an, solange noch
/// keine Aktion stattgefunden hat.
class FeedbackToast extends StatelessWidget {
  final String? message;

  const FeedbackToast({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return HudPanel(
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }
}
