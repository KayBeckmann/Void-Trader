import 'package:flutter/material.dart';

/// Gemeinsame Optik für alle HUD-Kacheln (Roadmap UI-02/UI-08) — eine
/// Stelle für Panel-Hintergrund/-Radius, damit ein späterer visueller
/// Feinschliff (UI-08: "einheitliche Panel-Farben, warme Akzentfarbe")
/// nicht jedes Panel einzeln anfassen muss.
class HudPanel extends StatelessWidget {
  final Widget child;
  final Color color;

  const HudPanel({super.key, required this.child, this.color = const Color(0xB0000000)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: child,
    );
  }
}
