import 'package:flutter/material.dart';
import '../../../core/data/building_repository.dart';
import '../../../core/domain/base_state.dart';
import '../../../core/domain/building.dart';
import '../../../core/domain/commodity.dart';
import '../../../core/domain/crew.dart';
import '../../../shared/theme/app_colors.dart';

class BaseOverviewScreen extends StatefulWidget {
  final BaseState base;
  final Inventory playerInventory;
  final double playerCredits;
  final VoidCallback onCreditsChanged;
  final VoidCallback onClose;

  const BaseOverviewScreen({
    super.key,
    required this.base,
    required this.playerInventory,
    required this.playerCredits,
    required this.onCreditsChanged,
    required this.onClose,
  });

  @override
  State<BaseOverviewScreen> createState() => _BaseOverviewScreenState();
}

class _BaseOverviewScreenState extends State<BaseOverviewScreen> {
  BuildingDef? _selectedBuild;
  String? _message;
  List<BuildingDef> _buildableDefs = [];
  PlacedBuilding? _activeBuilding;

  @override
  void initState() {
    super.initState();
    _loadBuildable();
  }

  Future<void> _loadBuildable() async {
    final defs = await BuildingRepository.loadAll();
    if (mounted) {
      setState(() => _buildableDefs = defs.where((d) => !d.isStub).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.base;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main split: map + right palette
          Column(
            children: [
              SizedBox(height: topPad),
              _BaseAppBar(base: base, onClose: widget.onClose),
              Expanded(
                child: Row(
                  children: [
                    // Map area
                    Expanded(
                      child: _MapCanvas(
                        base: base,
                        selectedDef: _selectedBuild,
                        activeBuilding: _activeBuilding,
                        onTileTap: _handleTileTap,
                        onBuildingTap: (b) =>
                            setState(() => _activeBuilding = b),
                      ),
                    ),
                    // Right palette
                    _BuildPalette(
                      defs: _buildableDefs,
                      selected: _selectedBuild,
                      playerInventory: widget.playerInventory,
                      playerCredits: widget.playerCredits,
                      onSelect: (d) => setState(() {
                        _selectedBuild = d;
                        _message = '"${d.name}" platzieren';
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Building popup
          if (_activeBuilding != null)
            Positioned(
              top: topPad + 56 + 20,
              left: 16,
              right: 96,
              child: _BuildingPopup(
                building: _activeBuilding!,
                onDismiss: () => setState(() => _activeBuilding = null),
              ),
            ),

          // Bottom HUD panel (above nav bar)
          Positioned(
            bottom: 72, // nav bar height
            left: 16,
            right: 96, // leave room for the right palette
            child: _BottomHud(base: base, onCrewTap: _openCrewSheet),
          ),

          // Feedback toast
          if (_message != null)
            Positioned(
              top: topPad + 60,
              left: 16,
              right: 96,
              child: _Toast(
                message: _message!,
                onDismiss: () => setState(() => _message = null),
              ),
            ),
        ],
      ),
    );
  }

  void _handleTileTap(int gx, int gy) {
    if (_selectedBuild == null) {
      final existing = widget.base.buildingAt(gx, gy);
      if (existing != null) {
        setState(() => _activeBuilding = existing);
      }
      return;
    }
    final success = widget.base.placeBuilding(
        _selectedBuild!, gx, gy, widget.playerInventory);
    setState(() {
      if (success) {
        _message = '${_selectedBuild!.name} gebaut!';
        _selectedBuild = null;
        _activeBuilding = null;
      } else {
        _message = 'Kein Platz oder fehlende Materialien.';
      }
    });
  }

  void _openCrewSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(),
      builder: (_) => _CrewSheet(
        base: widget.base,
        onHire: (role) => setState(() {
          if (widget.playerCredits >= 500) {
            widget.base.hireCrew(role);
            widget.onCreditsChanged();
          } else {
            Navigator.pop(context);
            setState(() => _message = 'Nicht genug Credits (500 CR Einstellungsgebühr)');
          }
        }),
      ),
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────────────────────

class _BaseAppBar extends StatelessWidget {
  final BaseState base;
  final VoidCallback onClose;
  const _BaseAppBar({required this.base, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.30),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.hub_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              base.planetName.toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontSize: 16,
                    letterSpacing: 0.08,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Day/night indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (base.isNight ? AppColors.tertiary : AppColors.secondary)
                  .withValues(alpha: 0.10),
              border: Border.all(
                color: (base.isNight ? AppColors.tertiary : AppColors.secondary)
                    .withValues(alpha: 0.50),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  base.isNight ? Icons.nightlight_outlined : Icons.light_mode_outlined,
                  size: 12,
                  color: base.isNight ? AppColors.tertiary : AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  base.isNight ? 'NACHT' : 'TAG',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: base.isNight ? AppColors.tertiary : AppColors.secondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 18, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

// ── Map Canvas ────────────────────────────────────────────────────────────────

class _MapCanvas extends StatelessWidget {
  final BaseState base;
  final BuildingDef? selectedDef;
  final PlacedBuilding? activeBuilding;
  final void Function(int, int) onTileTap;
  final ValueChanged<PlacedBuilding> onBuildingTap;

  const _MapCanvas({
    required this.base,
    required this.selectedDef,
    required this.activeBuilding,
    required this.onTileTap,
    required this.onBuildingTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final tileW = constraints.maxWidth / BaseState.gridWidth;
      final tileH = constraints.maxHeight / BaseState.gridHeight;
      final tileSize = tileW < tileH ? tileW : tileH;

      return Stack(
        children: [
          // Tactical grid background
          Positioned.fill(
            child: CustomPaint(
              painter: _TacticalGridPainter(
                cols: BaseState.gridWidth,
                rows: BaseState.gridHeight,
                tileSize: tileSize,
              ),
            ),
          ),
          // Tiles
          ...List.generate(BaseState.gridHeight, (gy) {
            return List.generate(BaseState.gridWidth, (gx) {
              return _GridTile(
                base: base,
                gx: gx,
                gy: gy,
                tileSize: tileSize,
                selectedDef: selectedDef,
                activeBuilding: activeBuilding,
                onTap: () => onTileTap(gx, gy),
                onBuildingTap: onBuildingTap,
              );
            });
          }).expand((r) => r),
        ],
      );
    });
  }
}

class _TacticalGridPainter extends CustomPainter {
  final int cols;
  final int rows;
  final double tileSize;

  const _TacticalGridPainter({
    required this.cols,
    required this.rows,
    required this.tileSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Planet surface gradient base
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          AppColors.surfaceContainerHigh.withValues(alpha: 0.80),
          AppColors.background,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Cyan tactical grid lines
    final gridPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (int x = 0; x <= cols; x++) {
      canvas.drawLine(
          Offset(x * tileSize, 0), Offset(x * tileSize, size.height), gridPaint);
    }
    for (int y = 0; y <= rows; y++) {
      canvas.drawLine(
          Offset(0, y * tileSize), Offset(size.width, y * tileSize), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_TacticalGridPainter old) => false;
}

class _GridTile extends StatelessWidget {
  final BaseState base;
  final int gx, gy;
  final double tileSize;
  final BuildingDef? selectedDef;
  final PlacedBuilding? activeBuilding;
  final VoidCallback onTap;
  final ValueChanged<PlacedBuilding> onBuildingTap;

  const _GridTile({
    required this.base,
    required this.gx,
    required this.gy,
    required this.tileSize,
    required this.selectedDef,
    required this.activeBuilding,
    required this.onTap,
    required this.onBuildingTap,
  });

  @override
  Widget build(BuildContext context) {
    final building = base.buildingAt(gx, gy);
    final cellId = base.cellAt(gx, gy);
    final isAnchor = building != null && building.gridX == gx && building.gridY == gy;
    final isOccupied = cellId != null && !isAnchor;
    final isResourceNode = base.resourceNodes.any((n) => n.gridX == gx && n.gridY == gy);
    final isActive = activeBuilding?.gridX == gx && activeBuilding?.gridY == gy;

    if (isOccupied) return const SizedBox.shrink();

    final gridSpan = isAnchor ? building.def.gridSize.toDouble() : 1.0;
    final px = gx * tileSize;
    final py = gy * tileSize;

    return Positioned(
      left: px,
      top: py,
      width: tileSize * gridSpan,
      height: tileSize * gridSpan,
      child: GestureDetector(
        onTap: isAnchor ? () => onBuildingTap(building) : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _bgColor(building, isResourceNode, isActive),
            border: Border.all(
              color: _borderColor(building, isResourceNode, isActive),
              width: isActive ? 1.5 : 0.8,
            ),
          ),
          child: isAnchor
              ? _BuildingIcon(building: building, isActive: isActive)
              : isResourceNode
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary.withValues(alpha: 0.60),
                        ),
                      ),
                    )
                  : null,
        ),
      ),
    );
  }

  Color _bgColor(PlacedBuilding? b, bool node, bool active) {
    if (b != null) {
      if (active) return AppColors.primary.withValues(alpha: 0.15);
      return b.isActive
          ? AppColors.surfaceContainerHigh
          : AppColors.surfaceContainerLowest;
    }
    if (node) return AppColors.secondary.withValues(alpha: 0.05);
    return Colors.transparent;
  }

  Color _borderColor(PlacedBuilding? b, bool node, bool active) {
    if (b != null) {
      if (active) return AppColors.primary;
      return b.isActive ? AppColors.outlineVariant : AppColors.surfaceContainerHigh;
    }
    if (node) return AppColors.secondary.withValues(alpha: 0.20);
    return Colors.transparent;
  }
}

class _BuildingIcon extends StatelessWidget {
  final PlacedBuilding building;
  final bool isActive;

  const _BuildingIcon({required this.building, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = building.isActive
        ? (isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.80))
        : AppColors.outline;
    final size = building.def.gridSize == 2 ? 28.0 : 18.0;

    return Stack(
      children: [
        Center(
          child: Icon(_iconFor(building.def.category), color: color, size: size),
        ),
        Positioned(
          top: 2,
          left: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            color: AppColors.surfaceContainer,
            child: Text(
              _shortName(building.def.name),
              style: const TextStyle(
                color: AppColors.outlineVariant,
                fontSize: 7,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(BuildingCategory cat) => switch (cat) {
        BuildingCategory.energy => Icons.bolt,
        BuildingCategory.extraction => Icons.precision_manufacturing_outlined,
        BuildingCategory.production => Icons.factory_outlined,
        BuildingCategory.storage => Icons.warehouse_outlined,
        BuildingCategory.defense => Icons.shield_outlined,
        BuildingCategory.special => Icons.biotech_outlined,
      };

  String _shortName(String name) {
    final parts = name.split(' ');
    return parts.map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }
}

// ── Build Palette (Right Sidebar) ─────────────────────────────────────────────

class _BuildPalette extends StatelessWidget {
  final List<BuildingDef> defs;
  final BuildingDef? selected;
  final Inventory playerInventory;
  final double playerCredits;
  final ValueChanged<BuildingDef> onSelect;

  const _BuildPalette({
    required this.defs,
    required this.selected,
    required this.playerInventory,
    required this.playerCredits,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.95),
        border: Border(
          left: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.30),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.20),
                ),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.construction_outlined,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          // Building list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              itemCount: defs.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final def = defs[i];
                final isSelected = selected?.id == def.id;
                final canAfford = def.buildCost.every(
                  (c) => playerInventory.quantityOf(c.commodityId) >= c.quantity,
                );
                return _PaletteItem(
                  def: def,
                  isSelected: isSelected,
                  canAfford: canAfford,
                  onTap: canAfford ? () => onSelect(def) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteItem extends StatelessWidget {
  final BuildingDef def;
  final bool isSelected;
  final bool canAfford;
  final VoidCallback? onTap;

  const _PaletteItem({
    required this.def,
    required this.isSelected,
    required this.canAfford,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = canAfford
        ? (isSelected ? AppColors.primary : AppColors.onSurfaceVariant)
        : AppColors.outline.withValues(alpha: 0.50);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.60,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outline,
            ),
          ),
          child: Column(
            children: [
              Icon(_iconFor(def.category), size: 20, color: color),
              const SizedBox(height: 3),
              Text(
                def.name.split(' ').first,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${def.energyBalance.toStringAsFixed(0)}⚡',
                style: TextStyle(
                  color: def.energyBalance >= 0
                      ? AppColors.secondary
                      : AppColors.error,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(BuildingCategory cat) => switch (cat) {
        BuildingCategory.energy => Icons.bolt,
        BuildingCategory.extraction => Icons.precision_manufacturing_outlined,
        BuildingCategory.production => Icons.factory_outlined,
        BuildingCategory.storage => Icons.warehouse_outlined,
        BuildingCategory.defense => Icons.shield_outlined,
        BuildingCategory.special => Icons.biotech_outlined,
      };
}

// ── Building Popup ────────────────────────────────────────────────────────────

class _BuildingPopup extends StatelessWidget {
  final PlacedBuilding building;
  final VoidCallback onDismiss;

  const _BuildingPopup({required this.building, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.95),
        border: Border.all(color: AppColors.primary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                building.def.name.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 0.12,
                    ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close, size: 14, color: AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            building.def.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 12,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Progress bar (energy balance as proxy)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ENERGIE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.outlineVariant,
                      fontSize: 9,
                    ),
              ),
              Text(
                '${building.def.energyBalance >= 0 ? '+' : ''}${building.def.energyBalance.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 10-segment progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outline),
            ),
            padding: const EdgeInsets.all(1),
            child: Row(
              children: List.generate(10, (i) {
                final active = building.isActive && i < 7;
                return Expanded(
                  child: Container(
                    margin: i < 9
                        ? const EdgeInsets.only(right: 1)
                        : EdgeInsets.zero,
                    color: active
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.10),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom HUD Panel ──────────────────────────────────────────────────────────

class _BottomHud extends StatelessWidget {
  final BaseState base;
  final VoidCallback onCrewTap;

  const _BottomHud({required this.base, required this.onCrewTap});

  @override
  Widget build(BuildContext context) {
    final power = base.energyProduced;
    final maxPower = power + base.energyConsumed.abs();
    final powerFill = maxPower > 0 ? (power / maxPower).clamp(0.0, 1.0) : 0.0;
    final poweredSegments = (powerFill * 10).round();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.90),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: metrics
          Row(
            children: [
              _HudMetric(
                icon: Icons.group_outlined,
                label: 'CREW',
                value: '${base.crew.length}',
                color: AppColors.primary,
                onTap: onCrewTap,
              ),
              const SizedBox(width: 8),
              _HudMetric(
                icon: Icons.inventory_2_outlined,
                label: 'LAGER',
                value: '${base.buildings.length * 10}%',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.light_mode_outlined, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      base.isNight ? 'NACHT' : 'TAG',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Power bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 12, color: AppColors.outlineVariant),
                      const SizedBox(width: 4),
                      Text(
                        'NETZLEISTUNG',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.outlineVariant,
                            ),
                      ),
                    ],
                  ),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      children: [
                        TextSpan(
                          text: power.toStringAsFixed(0),
                          style: const TextStyle(color: AppColors.onSurface),
                        ),
                        TextSpan(
                          text: '/${maxPower.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.outlineVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(color: AppColors.outline),
                ),
                padding: const EdgeInsets.all(1),
                child: Row(
                  children: List.generate(10, (i) {
                    final filled = i < poweredSegments;
                    return Expanded(
                      child: Container(
                        margin: i < 9
                            ? const EdgeInsets.only(right: 2)
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: filled
                              ? AppColors.secondary
                              : AppColors.surfaceContainer,
                          boxShadow: filled
                              ? [
                                  BoxShadow(
                                    color: AppColors.secondaryContainer
                                        .withValues(alpha: 0.80),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _HudMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.60),
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.outlineVariant,
                    fontSize: 8,
                    letterSpacing: 0.08,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feedback Toast ────────────────────────────────────────────────────────────

class _Toast extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _Toast({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 14, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

// ── Crew Sheet ────────────────────────────────────────────────────────────────

class _CrewSheet extends StatelessWidget {
  final BaseState base;
  final ValueChanged<CrewRole> onHire;

  const _CrewSheet({required this.base, required this.onHire});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              color: AppColors.outlineVariant,
            ),
          ),
          Text(
            'CREW — ${base.crew.length} MITGLIEDER',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'EINSTELLEN (500 CR)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          ...CrewRole.values.map((role) => _HireRow(role: role, onHire: onHire)),
          if (base.crew.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'AKTUELLE CREW',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            ...base.crew.map((m) => _CrewRow(member: m)),
          ],
        ],
      ),
    );
  }
}

class _HireRow extends StatelessWidget {
  final CrewRole role;
  final ValueChanged<CrewRole> onHire;

  const _HireRow({required this.role, required this.onHire});

  @override
  Widget build(BuildContext context) {
    const wages = {
      CrewRole.worker: 80,
      CrewRole.researcher: 200,
      CrewRole.pilot: 150,
      CrewRole.guard: 120,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => onHire(role),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(_roleIcon(role), size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _roleName(role),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${wages[role]} CR/Tag',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(CrewRole r) => switch (r) {
        CrewRole.worker => Icons.hardware_outlined,
        CrewRole.researcher => Icons.science_outlined,
        CrewRole.pilot => Icons.flight_outlined,
        CrewRole.guard => Icons.security_outlined,
      };

  String _roleName(CrewRole r) => switch (r) {
        CrewRole.worker => 'Arbeiter (+20% Prod.)',
        CrewRole.researcher => 'Forscher (Techtree)',
        CrewRole.pilot => 'Pilot (Flotte)',
        CrewRole.guard => 'Wache (Verteidigung)',
      };
}

class _CrewRow extends StatelessWidget {
  final CrewMember member;
  const _CrewRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            member.name,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(width: 8),
          Text(
            member.roleLabel,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: member.isAssigned
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              border: Border.all(
                color: member.isAssigned
                    ? AppColors.primary.withValues(alpha: 0.50)
                    : AppColors.outlineVariant,
              ),
            ),
            child: Text(
              member.isAssigned ? 'ZUGEWIESEN' : 'FREI',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: member.isAssigned
                        ? AppColors.primary
                        : AppColors.outline,
                    fontSize: 9,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
