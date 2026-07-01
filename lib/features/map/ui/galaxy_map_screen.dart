import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class GalaxyMapScreen extends StatefulWidget {
  const GalaxyMapScreen({super.key});

  @override
  State<GalaxyMapScreen> createState() => _GalaxyMapScreenState();
}

class _GalaxyMapScreenState extends State<GalaxyMapScreen> {
  _SystemNode? _selected = _systems[0]; // Helios Prime pre-selected
  final _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    // Heights: header ~52, sub-header ~78, bottom-nav ~72
    const headerH = 52.0;
    const subHeaderH = 78.0;
    const infoPanelH = 172.0;
    const navH = 72.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map canvas — fills whole screen behind overlays
          Positioned.fill(
            child: _MapCanvas(
              selected: _selected,
              onSelect: (s) => setState(() => _selected = s),
              filter: _filter,
              topOffset: topPad + headerH + subHeaderH,
              bottomOffset: navH + (_selected != null ? infoPanelH : 0),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _MapHeader(topPad: topPad),
          ),

          // Sub-header (search + faction rep)
          Positioned(
            top: topPad + headerH,
            left: 0,
            right: 0,
            child: _SubHeader(
              controller: _searchCtrl,
              onSearch: (v) => setState(() => _filter = v.toLowerCase()),
            ),
          ),

          // Info panel (above bottom nav)
          if (_selected != null)
            Positioned(
              bottom: navH + 8,
              left: 12,
              right: 12,
              child: _InfoPanel(
                system: _selected!,
                onDismiss: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

enum _Tier { core, frontier, outer }

class _SystemNode {
  final String id;
  final String name;
  final _Tier tier;
  final double relX; // 0..1
  final double relY; // 0..1
  final String faction;
  final String topExport;
  final String topImport;
  final String threat;

  const _SystemNode({
    required this.id,
    required this.name,
    required this.tier,
    required this.relX,
    required this.relY,
    required this.faction,
    required this.topExport,
    required this.topImport,
    required this.threat,
  });
}

const _systems = [
  _SystemNode(
    id: 'helios',
    name: 'Helios Prime',
    tier: _Tier.core,
    relX: 0.50,
    relY: 0.45,
    faction: 'Terran Command',
    topExport: 'Mikrochips, H₂O',
    topImport: 'Uran, Nahrung',
    threat: 'NIEDRIG',
  ),
  _SystemNode(
    id: 'sirius',
    name: 'Sirius',
    tier: _Tier.core,
    relX: 0.30,
    relY: 0.25,
    faction: 'Terran Command',
    topExport: 'Stahl, Polymer',
    topImport: 'Energie, Krypto',
    threat: 'GERING',
  ),
  _SystemNode(
    id: 'vega',
    name: 'Vega',
    tier: _Tier.core,
    relX: 0.75,
    relY: 0.35,
    faction: 'Syndikat',
    topExport: 'Luxusgüter',
    topImport: 'Treibstoff',
    threat: 'MITTEL',
  ),
  _SystemNode(
    id: 'tarsus',
    name: 'Tarsus',
    tier: _Tier.frontier,
    relX: 0.60,
    relY: 0.70,
    faction: 'Outriders',
    topExport: 'Erze',
    topImport: 'Lebensmittel',
    threat: 'HOCH',
  ),
  _SystemNode(
    id: 'unknown',
    name: 'Unbekannt',
    tier: _Tier.outer,
    relX: 0.20,
    relY: 0.80,
    faction: '???',
    topExport: '—',
    topImport: '—',
    threat: 'KRITISCH',
  ),
];

const _connections = [
  ('helios', 'sirius', _Tier.core),
  ('helios', 'vega', _Tier.core),
  ('helios', 'tarsus', _Tier.frontier),
  ('tarsus', 'unknown', _Tier.outer),
];

// ── Map Canvas ────────────────────────────────────────────────────────────────

class _MapCanvas extends StatelessWidget {
  final _SystemNode? selected;
  final ValueChanged<_SystemNode> onSelect;
  final String filter;
  final double topOffset;
  final double bottomOffset;

  const _MapCanvas({
    required this.selected,
    required this.onSelect,
    required this.filter,
    required this.topOffset,
    required this.bottomOffset,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      // Usable area for map content
      final usableTop = topOffset;
      final usableH = h - topOffset - bottomOffset;

      final visible = filter.isEmpty
          ? _systems
          : _systems.where((s) => s.name.toLowerCase().contains(filter)).toList();

      return Stack(
        children: [
          // Grid background
          Positioned.fill(child: _GridBackground()),

          // Connection lines
          CustomPaint(
            size: Size(w, h),
            painter: _ConnectionPainter(
              systems: _systems,
              connections: _connections,
              canvasW: w,
              canvasH: h,
              usableTop: usableTop,
              usableH: usableH,
            ),
          ),

          // System nodes
          for (final sys in visible)
            _nodeWidget(context, sys, w, h, usableTop, usableH),
        ],
      );
    });
  }

  Widget _nodeWidget(BuildContext ctx, _SystemNode sys, double w, double h,
      double usableTop, double usableH) {
    final x = sys.relX * w;
    final y = usableTop + sys.relY * usableH;
    final isSelected = selected?.id == sys.id;
    return Positioned(
      left: x,
      top: y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          onTap: () => onSelect(sys),
          child: _SystemMarker(system: sys, selected: isSelected),
        ),
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _ConnectionPainter extends CustomPainter {
  final List<_SystemNode> systems;
  final List<(String, String, _Tier)> connections;
  final double canvasW;
  final double canvasH;
  final double usableTop;
  final double usableH;

  const _ConnectionPainter({
    required this.systems,
    required this.connections,
    required this.canvasW,
    required this.canvasH,
    required this.usableTop,
    required this.usableH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final s in systems) s.id: s};
    for (final (a, b, tier) in connections) {
      final sA = byId[a];
      final sB = byId[b];
      if (sA == null || sB == null) continue;
      final pA = _pos(sA);
      final pB = _pos(sB);

      final color = switch (tier) {
        _Tier.core => AppColors.primaryContainer,
        _Tier.frontier => AppColors.secondary,
        _Tier.outer => AppColors.outline,
      };
      final opacity = switch (tier) {
        _Tier.core => 0.70,
        _Tier.frontier => 0.50,
        _Tier.outer => 0.30,
      };
      final dashed = tier != _Tier.core;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = tier == _Tier.core ? 1.5 : 1.0
        ..style = PaintingStyle.stroke;

      if (dashed) {
        _drawDashed(canvas, pA, pB, paint, tier == _Tier.frontier ? 4 : 2);
      } else {
        // Glow for core lanes
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.25)
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawLine(pA, pB, glowPaint);
        canvas.drawLine(pA, pB, paint);
      }
    }
  }

  Offset _pos(_SystemNode s) => Offset(
        s.relX * canvasW,
        usableTop + s.relY * usableH,
      );

  void _drawDashed(Canvas canvas, Offset a, Offset b, Paint p, double dashLen) {
    final delta = b - a;
    final dist = delta.distance;
    final dir = delta / dist;
    double traveled = 0;
    bool drawing = true;
    while (traveled < dist) {
      final segEnd = math.min(traveled + dashLen, dist);
      if (drawing) {
        canvas.drawLine(a + dir * traveled, a + dir * segEnd, p);
      }
      traveled = segEnd + dashLen * 0.5;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_ConnectionPainter old) => false;
}

class _SystemMarker extends StatelessWidget {
  final _SystemNode system;
  final bool selected;

  const _SystemMarker({required this.system, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = switch (system.tier) {
      _Tier.core => selected ? AppColors.primary : AppColors.primaryFixedDim,
      _Tier.frontier => AppColors.secondary,
      _Tier.outer => AppColors.outline,
    };
    final dotSize = switch (system.tier) {
      _Tier.core => 14.0,
      _Tier.frontier => 10.0,
      _Tier.outer => 8.0,
    };
    final opacity = system.tier == _Tier.outer ? 0.50 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (selected)
                Container(
                  width: dotSize + 14,
                  height: dotSize + 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: AppColors.surfaceContainerHighest,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: selected ? 0.80 : 0.50),
                      blurRadius: selected ? 12 : 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: selected ? 0.95 : 0.60),
              border: Border.all(
                color: color.withValues(alpha: selected ? 0.50 : 0.30),
                width: 1,
              ),
            ),
            child: Text(
              system.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _MapHeader extends StatelessWidget {
  final double topPad;
  const _MapHeader({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: EdgeInsets.fromLTRB(8, topPad + 6, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.80),
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.10),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.rocket_launch, color: AppColors.primary, size: 22),
              const Spacer(),
              Text(
                'GALAXIS-KARTE',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryFixed,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryContainer.withValues(alpha: 0.60),
                          blurRadius: 6,
                        ),
                      ],
                    ),
              ),
              const Spacer(),
              Icon(Icons.settings_outlined, color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-Header ────────────────────────────────────────────────────────────────

class _SubHeader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  const _SubHeader({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.90),
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.30),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search bar
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.50),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(Icons.search, size: 16, color: AppColors.outline),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onSearch,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'Systeme suchen...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Faction rep row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FactionRep(Icons.military_tech, 85, AppColors.primary),
                  _FactionRep(Icons.monetization_on_outlined, 42, AppColors.secondary),
                  _FactionRep(Icons.explore_outlined, 12, AppColors.tertiary),
                  _FactionRep(Icons.warning_amber_outlined, -99, AppColors.error),
                  _FactionRep(Icons.memory_outlined, 0, AppColors.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactionRep extends StatelessWidget {
  final IconData icon;
  final int rep;
  final Color color;
  const _FactionRep(this.icon, this.rep, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          rep.toString(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

// ── Info Panel ────────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  final _SystemNode system;
  final VoidCallback onDismiss;

  const _InfoPanel({required this.system, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.50),
        ),
      ),
      child: Stack(
        children: [
          // Corner brackets (DESIGN.md "framing")
          _bracket(top: 0, left: 0, right: null, bottom: null),
          _bracket(top: 0, left: null, right: 0, bottom: null),
          _bracket(top: null, left: 0, right: null, bottom: 0),
          _bracket(top: null, left: null, right: 0, bottom: 0),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            system.name.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            system.faction,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'BEDROHUNG',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.outlineVariant),
                        ),
                        Text(
                          system.threat,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryFixed,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onDismiss,
                      child: Icon(Icons.close, size: 16, color: AppColors.outline),
                    ),
                  ],
                ),

                // Market summary
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.30),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      _MarketRow(label: 'EXPORT', value: system.topExport),
                      const SizedBox(height: 4),
                      _MarketRow(label: 'IMPORT', value: system.topImport),
                    ],
                  ),
                ),

                // Action button
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.20),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'ZIEL SETZEN',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                letterSpacing: 0.20,
                              ),
                        ),
                      ],
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

  Widget _bracket({
    double? top,
    double? left,
    double? right,
    double? bottom,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          border: Border(
            top: top == 0
                ? BorderSide(color: AppColors.primary.withValues(alpha: 0.50))
                : BorderSide.none,
            bottom: bottom == 0
                ? BorderSide(color: AppColors.primary.withValues(alpha: 0.50))
                : BorderSide.none,
            left: left == 0
                ? BorderSide(color: AppColors.primary.withValues(alpha: 0.50))
                : BorderSide.none,
            right: right == 0
                ? BorderSide(color: AppColors.primary.withValues(alpha: 0.50))
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  final String label;
  final String value;
  const _MarketRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.outline,
                letterSpacing: 0.12,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
      ],
    );
  }
}
