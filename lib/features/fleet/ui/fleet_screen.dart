import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  _Block? _selected;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SizedBox(height: topPad),
          _FleetHeader(),
          Expanded(
            child: Row(
              children: [
                // Block palette (left sidebar)
                _BlockPalette(onDrop: (b) => setState(() => _selected = b)),
                // Editor canvas
                Expanded(
                  child: _EditorCanvas(
                    selected: _selected,
                    onDeselect: () => setState(() => _selected = null),
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

// ── Data ──────────────────────────────────────────────────────────────────────

enum _BlockType { trigger, action }

class _Block {
  final String id;
  final String label;
  final String description;
  final _BlockType type;
  final IconData icon;

  const _Block({
    required this.id,
    required this.label,
    required this.description,
    required this.type,
    required this.icon,
  });
}

const _triggers = [
  _Block(
    id: 'timer',
    label: 'Timer',
    description: 'Alle 10s',
    type: _BlockType.trigger,
    icon: Icons.schedule,
  ),
  _Block(
    id: 'cargo_full',
    label: 'Cargo voll',
    description: 'Kapazität > 95%',
    type: _BlockType.trigger,
    icon: Icons.inventory_2_outlined,
  ),
  _Block(
    id: 'enemy_detected',
    label: 'Feind erkannt',
    description: 'Radarreichweite',
    type: _BlockType.trigger,
    icon: Icons.warning_amber_outlined,
  ),
];

const _actions = [
  _Block(
    id: 'mine',
    label: 'Abbau',
    description: 'Ziel: Asteroid',
    type: _BlockType.action,
    icon: Icons.precision_manufacturing_outlined,
  ),
  _Block(
    id: 'nav',
    label: 'Navigation',
    description: 'Autopilot → Hub',
    type: _BlockType.action,
    icon: Icons.flight_land_outlined,
  ),
  _Block(
    id: 'attack',
    label: 'Angriff',
    description: 'Waffe feuern',
    type: _BlockType.action,
    icon: Icons.my_location_outlined,
  ),
];

// Prebuilt canvas nodes for the mockup (cannot be const: record fields from list index)
final _canvasNodes = [
  (block: _triggers[0], x: 0.50, y: 0.15),
  (block: _actions[0], x: 0.30, y: 0.40),
  (block: _actions[1], x: 0.70, y: 0.40),
  (block: _triggers[1], x: 0.50, y: 0.65),
  (block: _actions[2], x: 0.50, y: 0.85),
];

// ── Header ────────────────────────────────────────────────────────────────────

class _FleetHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
              Icon(Icons.rocket_launch, color: AppColors.primary, size: 20),
              const Spacer(),
              Text(
                'FLOTTEN-EDITOR',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryFixed,
                      fontSize: 16,
                      letterSpacing: 0.10,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryContainer.withValues(alpha: 0.60),
                          blurRadius: 6,
                        ),
                      ],
                    ),
              ),
              const Spacer(),
              Icon(Icons.settings_outlined, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Block Palette ─────────────────────────────────────────────────────────────

class _BlockPalette extends StatelessWidget {
  final ValueChanged<_Block> onDrop;

  const _BlockPalette({required this.onDrop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.90),
        border: Border(
          right: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.30),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _PaletteSection(
            label: 'TRIGGER',
            icon: Icons.play_circle_outline,
            color: AppColors.primary,
            blocks: _triggers,
            onTap: onDrop,
          ),
          const SizedBox(height: 12),
          _PaletteSection(
            label: 'AKTIONEN',
            icon: Icons.bolt,
            color: AppColors.secondary,
            blocks: _actions,
            onTap: onDrop,
          ),
        ],
      ),
    );
  }
}

class _PaletteSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<_Block> blocks;
  final ValueChanged<_Block> onTap;

  const _PaletteSection({
    required this.label,
    required this.icon,
    required this.color,
    required this.blocks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...blocks.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => onTap(b),
                child: _PaletteCard(block: b),
              ),
            )),
      ],
    );
  }
}

class _PaletteCard extends StatelessWidget {
  final _Block block;
  const _PaletteCard({required this.block});

  @override
  Widget build(BuildContext context) {
    final color = block.type == _BlockType.trigger
        ? AppColors.primary
        : AppColors.secondary;
    final onColor = block.type == _BlockType.trigger
        ? AppColors.onPrimary
        : AppColors.onSecondary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            color: color,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    block.label,
                    style: TextStyle(
                      color: onColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(block.icon, size: 10, color: onColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              block.description,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 9,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Editor Canvas ─────────────────────────────────────────────────────────────

class _EditorCanvas extends StatelessWidget {
  final _Block? selected;
  final VoidCallback onDeselect;

  const _EditorCanvas({required this.selected, required this.onDeselect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return GestureDetector(
        onTap: onDeselect,
        child: Stack(
          children: [
            // Grid background
            Positioned.fill(child: CustomPaint(painter: _CanvasGridPainter())),

            // Connection lines
            CustomPaint(
              size: Size(w, h),
              painter: _ConnectionPainter(nodes: _canvasNodes, w: w, h: h),
            ),

            // Blocks
            for (final node in _canvasNodes)
              _CanvasBlock(
                block: node.block,
                x: node.x * w,
                y: node.y * h,
                isSelected: selected?.id == node.block.id,
              ),

            // Empty state overlay (when no real logic programmed)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'M3 — Drag-and-Drop-Editor in Entwicklung',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.outline.withValues(alpha: 0.50),
                      ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CanvasGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_CanvasGridPainter old) => false;
}

class _ConnectionPainter extends CustomPainter {
  final List<({_Block block, double x, double y})> nodes;
  final double w;
  final double h;

  const _ConnectionPainter({required this.nodes, required this.w, required this.h});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.40)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw orthogonal lines between consecutive nodes
    for (int i = 0; i < nodes.length - 1; i++) {
      final a = Offset(nodes[i].x * w, nodes[i].y * h);
      final b = Offset(nodes[i + 1].x * w, nodes[i + 1].y * h);
      // Orthogonal routing: vertical then horizontal
      final mid = Offset(a.dx, b.dy);
      canvas.drawLine(a, mid, paint);
      canvas.drawLine(mid, b, paint);
      // Port squares
      final portPaint = Paint()..color = AppColors.primary.withValues(alpha: 0.60);
      canvas.drawRect(Rect.fromCenter(center: a, width: 6, height: 6), portPaint);
      canvas.drawRect(Rect.fromCenter(center: b, width: 6, height: 6), portPaint);
    }
  }

  @override
  bool shouldRepaint(_ConnectionPainter old) => false;
}

class _CanvasBlock extends StatelessWidget {
  final _Block block;
  final double x;
  final double y;
  final bool isSelected;

  const _CanvasBlock({
    required this.block,
    required this.x,
    required this.y,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    const w = 100.0;
    const h = 56.0;
    final color = block.type == _BlockType.trigger
        ? AppColors.primary
        : AppColors.secondary;
    final onColor = block.type == _BlockType.trigger
        ? AppColors.onPrimary
        : AppColors.onSecondary;

    return Positioned(
      left: x - w / 2,
      top: y - h / 2,
      width: w,
      height: h,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              color: color,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      block.label,
                      style: TextStyle(
                        color: onColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(block.icon, size: 10, color: onColor),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  block.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
