import 'package:flutter/material.dart';
import 'package:vt_system/vt_system.dart';

import '../design_tokens.dart';

/// Vollbild-Overlay für die Systemkarte (Roadmap Phase 9, V1-Slice
/// "Systemkarte") — zeigt die Himmelskörper des aktuellen Systems als
/// beschriftete Punkte. Bewusst reine Darstellung ohne Reise-/
/// Flugmechanik: kein Andocken, keine Speedways, keine Interaktion mit
/// einzelnen Körpern — das sind spätere Phase-9-Schritte.
///
/// Bekommt das fertige [StarSystem] als reine Daten statt selbst auf
/// [VoidTraderGame] zuzugreifen — bleibt so mit Beispieldaten testbar
/// (siehe test/ui/widgets/), analog zu [MinimapPanel].
class SystemMapPanel extends StatelessWidget {
  final StarSystem system;
  final VoidCallback onClose;

  const SystemMapPanel({super.key, required this.system, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: const Color(0xF20B1220),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Systemkarte: ${system.name}',
                        style: const TextStyle(
                          color: VtColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: VtSpacing.md),
                    const Text(
                      'Schließen: Taste M oder Klick',
                      style: TextStyle(color: VtColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: VtSpacing.lg),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: VtColors.panelBackground,
                      borderRadius: BorderRadius.circular(VtRadii.panel),
                      border: Border.all(color: VtColors.panelBorder),
                    ),
                    child: CustomPaint(painter: _SystemMapPainter(system: system)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemMapPainter extends CustomPainter {
  final StarSystem system;

  _SystemMapPainter({required this.system});

  @override
  void paint(Canvas canvas, Size size) {
    if (system.bodies.isEmpty) return;

    // Alle Körper gleichmäßig in die verfügbare Fläche einpassen — die
    // rohen x/y-Werte aus vt_system sind beliebige "Systemkarten-
    // Einheiten", keine Pixel.
    final maxExtent = system.bodies
        .map((b) => [b.x.abs(), b.y.abs()].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);
    final scale = maxExtent == 0 ? 1.0 : (size.shortestSide / 2 - 40) / maxExtent;
    final center = Offset(size.width / 2, size.height / 2);

    for (final body in system.bodies) {
      final position = center + Offset(body.x * scale, body.y * scale);
      final paint = Paint()..color = _colorFor(body.type);
      canvas.drawCircle(position, _radiusFor(body.type), paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: body.name,
          style: const TextStyle(color: VtColors.textSecondary, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        position + Offset(-textPainter.width / 2, _radiusFor(body.type) + 4),
      );
    }
  }

  double _radiusFor(CelestialBodyType type) => switch (type) {
    CelestialBodyType.homePlanet => 14,
    CelestialBodyType.station => 8,
    CelestialBodyType.asteroidField => 6,
  };

  Color _colorFor(CelestialBodyType type) => switch (type) {
    CelestialBodyType.homePlanet => VtColors.accentGreen,
    CelestialBodyType.station => VtColors.accentCyan,
    CelestialBodyType.asteroidField => VtColors.textMuted,
  };

  @override
  bool shouldRepaint(covariant _SystemMapPainter oldDelegate) => oldDelegate.system != system;
}
