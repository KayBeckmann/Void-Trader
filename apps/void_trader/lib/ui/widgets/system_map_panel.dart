import 'package:flutter/material.dart';
import 'package:vt_system/vt_system.dart';

import '../design_tokens.dart';

/// Key des Karten-[CustomPaint] — eindeutig auffindbar für Tests (Tap-
/// Zielkoordinaten müssen sich exakt auf die Kartenfläche beziehen, nicht
/// auf das gesamte Overlay inklusive Titelzeile).
const systemMapCanvasKey = Key('systemMapCanvas');

/// Vollbild-Overlay für die Systemkarte (Roadmap Phase 9) — zeigt die
/// Himmelskörper des aktuellen Systems als beschriftete Punkte, hebt den
/// aktuellen Standort des Schiffs hervor, erlaubt einen Tap auf einen
/// anderen Körper als (weiterhin animationslose) Reise dorthin, und
/// bietet einen "Fracht verkaufen"- und einen "Vorräte kaufen"-Button,
/// sobald das Schiff an einer Handelsstation angedockt ist (Roadmap
/// Phase 9 V3 bzw. V8). Bewusst weiterhin ohne echte Flugmechanik: keine
/// Speedways — das sind spätere Phase-9-Schritte.
///
/// Bekommt System/Standort als reine Daten statt selbst auf
/// [VoidTraderGame] zuzugreifen — bleibt so mit Beispieldaten testbar
/// (siehe test/ui/widgets/), analog zu [MinimapPanel].
class SystemMapPanel extends StatelessWidget {
  final StarSystem system;
  final String currentBodyId;

  /// Aktueller Treibstoffstand des Schiffs (Roadmap Phase 9, V9:
  /// "Treibstoffverbrauch") — hier statt in der allgemeinen ResourceBar
  /// angezeigt, weil genau hier die Reiseentscheidung getroffen wird, die
  /// Treibstoff kostet (siehe VoidTraderGame.travelTo).
  final int shipFuel;
  final ValueChanged<String> onSelectBody;
  final VoidCallback onSellCargo;
  final VoidCallback onBuySupplies;
  final VoidCallback onClose;

  const SystemMapPanel({
    super.key,
    required this.system,
    required this.currentBodyId,
    required this.shipFuel,
    required this.onSelectBody,
    required this.onSellCargo,
    required this.onBuySupplies,
    required this.onClose,
  });

  /// Der Körper, an dem das Schiff gerade steht, falls es eine Station
  /// ist — bestimmt, ob der "Fracht verkaufen"-Button erscheint und zu
  /// welchem Preisniveau (Roadmap Phase 9 V5: unterschiedliche Stationen
  /// zahlen unterschiedlich viel, siehe [CelestialBody.priceMultiplier]).
  /// Aus den bereits vorhandenen [system]/[currentBodyId]-Daten
  /// abgeleitet statt eines eigenen Flags, damit es nie aus dem Takt
  /// geraten kann.
  CelestialBody? get _dockedStation {
    for (final body in system.bodies) {
      if (body.id == currentBodyId) {
        return body.type == CelestialBodyType.station ? body : null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  // Treibstoffstand direkt neben dem Titel (Roadmap V9) —
                  // immer sichtbar, während hier Reiseentscheidungen
                  // getroffen werden, die Treibstoff kosten.
                  const Icon(
                    Icons.local_gas_station_outlined,
                    color: VtColors.accentRed,
                    size: 18,
                  ),
                  const SizedBox(width: VtSpacing.xs),
                  Text(
                    '$shipFuel',
                    style: const TextStyle(
                      color: VtColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: VtSpacing.md),
                  IconButton(
                    onPressed: onClose,
                    tooltip: 'Schließen (M)',
                    icon: const Icon(
                      Icons.close,
                      color: VtColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Eigene Zeile statt Teil der Titel-Row (Roadmap V8): mit
              // zwei Stations-Buttons ("Vorräte kaufen" + "Fracht
              // verkaufen") passt das nicht mehr neben Titel + Schließen-
              // Button. Als direktes Column-Kind bekommt Wrap eine echte
              // Breitenbeschränkung und bricht bei Bedarf in eine zweite
              // Zeile um, statt einen RenderFlex-Overflow zu erzeugen
              // (dasselbe Muster wie ToolbeltPanel — dort funktioniert es
              // aus demselben Grund: Wrap braucht begrenzte, nicht
              // unbegrenzte Constraints, die es innerhalb einer Row als
              // Row-Geschwister eines Expanded nicht bekommt).
              if (_dockedStation case final station?) ...[
                const SizedBox(height: VtSpacing.sm),
                Wrap(
                  spacing: VtSpacing.sm,
                  runSpacing: VtSpacing.sm,
                  children: [
                    TextButton.icon(
                      onPressed: onBuySupplies,
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: VtColors.accentCyan,
                      ),
                      label: Text(
                        station.priceMultiplier == 1.0
                            ? 'Vorräte kaufen'
                            : 'Vorräte kaufen (×${station.priceMultiplier.toStringAsFixed(1)})',
                        style: const TextStyle(color: VtColors.accentCyan),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onSellCargo,
                      icon: const Icon(
                        Icons.sell_outlined,
                        color: VtColors.accentGreen,
                      ),
                      label: Text(
                        station.priceMultiplier == 1.0
                            ? 'Fracht verkaufen'
                            : 'Fracht verkaufen (×${station.priceMultiplier.toStringAsFixed(1)})',
                        style: const TextStyle(color: VtColors.accentGreen),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: VtSpacing.lg),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: VtColors.panelBackground,
                    borderRadius: BorderRadius.circular(VtRadii.panel),
                    border: Border.all(color: VtColors.panelBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      final positions = layoutSystemBodies(system.bodies, size);
                      return Stack(
                        children: [
                          CustomPaint(
                            key: systemMapCanvasKey,
                            size: size,
                            painter: _SystemMapPainter(
                              system: system,
                              positions: positions,
                              currentBodyId: currentBodyId,
                            ),
                          ),
                          for (final body in system.bodies)
                            _BodyTapTarget(
                              position: positions[body.id]!,
                              radius: _tapRadiusFor(body.type),
                              onTap: () => onSelectBody(body.id),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mindest-Trefferradius für einen Körper-Tap — deutlich größer als der
/// sichtbare Punkt (v.a. beim kleinen Asteroidengürtel-Symbol), damit die
/// Karte auch auf Touch-Geräten bedienbar bleibt.
double _tapRadiusFor(CelestialBodyType type) => switch (type) {
  CelestialBodyType.homePlanet => 24,
  CelestialBodyType.station => 20,
  CelestialBodyType.asteroidField => 20,
};

class _BodyTapTarget extends StatelessWidget {
  final Offset position;
  final double radius;
  final VoidCallback onTap;

  const _BodyTapTarget({
    required this.position,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - radius,
      top: position.dy - radius,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(width: radius * 2, height: radius * 2),
      ),
    );
  }
}

/// Bildet die "Systemkarten-Einheiten" aus [CelestialBody.x]/[y] auf
/// Bildschirmkoordinaten innerhalb von [canvasSize] ab — eine reine
/// Funktion statt in Painter und Tap-Zielen doppelt zu rechnen, damit
/// sichtbare Punkte und Trefferflächen immer exakt übereinstimmen.
Map<String, Offset> layoutSystemBodies(
  List<CelestialBody> bodies,
  Size canvasSize,
) {
  if (bodies.isEmpty) return {};

  final maxExtent = bodies
      .map((b) => [b.x.abs(), b.y.abs()].reduce((a, b) => a > b ? a : b))
      .reduce((a, b) => a > b ? a : b);
  final scale = maxExtent == 0
      ? 1.0
      : (canvasSize.shortestSide / 2 - 40) / maxExtent;
  final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

  return {
    for (final body in bodies)
      body.id: center + Offset(body.x * scale, body.y * scale),
  };
}

class _SystemMapPainter extends CustomPainter {
  final StarSystem system;
  final Map<String, Offset> positions;
  final String currentBodyId;

  _SystemMapPainter({
    required this.system,
    required this.positions,
    required this.currentBodyId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final body in system.bodies) {
      final position = positions[body.id]!;
      final radius = _visualRadiusFor(body.type);

      if (body.id == currentBodyId) {
        final ringPaint = Paint()
          ..color = VtColors.accentAmber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(position, radius + 6, ringPaint);
      }

      final paint = Paint()..color = _colorFor(body.type);
      canvas.drawCircle(position, radius, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: body.name,
          style: const TextStyle(color: VtColors.textSecondary, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        position + Offset(-textPainter.width / 2, radius + 4),
      );
    }
  }

  double _visualRadiusFor(CelestialBodyType type) => switch (type) {
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
  bool shouldRepaint(covariant _SystemMapPainter oldDelegate) =>
      oldDelegate.system != system ||
      oldDelegate.positions != positions ||
      oldDelegate.currentBodyId != currentBodyId;
}
