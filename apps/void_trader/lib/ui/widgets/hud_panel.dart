import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// Gemeinsame Optik für alle HUD-Kacheln (Roadmap UI-02/UI-08, seit HUD-10
/// auf zentrale [VtColors]/[VtRadii]-Tokens umgestellt statt eigener Magic
/// Colors) — ein Ort für Panel-Hintergrund/-Rand/-Radius, damit ein
/// visueller Feinschliff nicht jedes Panel einzeln anfassen muss.
///
/// Dunkles Glas mit dezentem Cyan-Rand ("spacy / rugged sci-fi / colony
/// operations" laut Roadmap-Designrichtung) statt generischer
/// Flutter-Standardkarten.
class HudPanel extends StatelessWidget {
  final Widget child;
  final Color color;

  /// Ob der dezente Rand gezeichnet wird — für sehr leise Hintergrund-
  /// Panels (z.B. Steuerungslegende) abschaltbar.
  final bool bordered;

  const HudPanel({
    super.key,
    required this.child,
    this.color = VtColors.panelBackground,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VtSpacing.md, vertical: VtSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(VtRadii.panel),
        border: bordered ? Border.all(color: VtColors.panelBorder, width: 1) : null,
      ),
      child: child,
    );
  }
}
