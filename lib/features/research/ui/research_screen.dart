import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  _TechNode? _selected;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Vertical center axis line
          Positioned(
            top: topPad + 52 + 40 + 16,
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(width: 1, color: AppColors.primary.withValues(alpha: 0.40)),
            ),
          ),

          Column(
            children: [
              SizedBox(height: topPad),
              // Header
              _ResearchHeader(),
              // Sub-header: resource counters
              _ResourceBar(),
              // Tech tree
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 80),
                  children: [
                    // Tier 1: Antrieb (root)
                    _TechRow(
                      nodes: [_techNodes[0]],
                      selected: _selected,
                      onSelect: (n) => setState(() => _selected = n),
                    ),
                    const _TechConnector(active: true),
                    // Tier 2: two branches
                    _TechRow(
                      nodes: [_techNodes[1], _techNodes[2]],
                      selected: _selected,
                      onSelect: (n) => setState(() => _selected = n),
                    ),
                    const _TechConnector(active: false),
                    // Tier 3
                    _TechRow(
                      nodes: [_techNodes[3]],
                      selected: _selected,
                      onSelect: (n) => setState(() => _selected = n),
                    ),
                    const _TechConnector(active: false),
                    // Tier 4
                    _TechRow(
                      nodes: [_techNodes[4], _techNodes[5]],
                      selected: _selected,
                      onSelect: (n) => setState(() => _selected = n),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Detail panel for selected node
          if (_selected != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: _NodeDetail(
                node: _selected!,
                onDismiss: () => setState(() => _selected = null),
                onResearch: () => setState(() {
                  // Unlock stub
                  _selected = null;
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Static tech tree data ─────────────────────────────────────────────────────

enum _TechStatus { unlocked, available, locked }

class _TechNode {
  final String id;
  final String category;
  final String name;
  final String description;
  final int level;
  final int maxLevel;
  final _TechStatus status;
  final int cost;

  const _TechNode({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.level,
    required this.maxLevel,
    required this.status,
    required this.cost,
  });
}

const _techNodes = [
  _TechNode(
    id: 'thrusters',
    category: 'ANTRIEB',
    name: 'Basic Thrusters',
    description: 'Grundlegende Antriebssysteme. Ermöglicht Raumflug.',
    level: 3,
    maxLevel: 3,
    status: _TechStatus.unlocked,
    cost: 0,
  ),
  _TechNode(
    id: 'refinery',
    category: 'INDUSTRIE',
    name: 'Refinery Mk I',
    description: 'Verarbeitet Roherze zu Industriegütern.',
    level: 1,
    maxLevel: 3,
    status: _TechStatus.unlocked,
    cost: 0,
  ),
  _TechNode(
    id: 'logistik',
    category: 'LOGISTIK-KI',
    name: 'Logistik-KI Alpha',
    description: 'Automatische Routenoptimierung für Frachtschiffe.',
    level: 0,
    maxLevel: 3,
    status: _TechStatus.available,
    cost: 120,
  ),
  _TechNode(
    id: 'shields',
    category: 'SCHILDE',
    name: 'Shield Calibration',
    description: 'Verbesserte Schildfrequenzen. +20% Kapazität.',
    level: 0,
    maxLevel: 5,
    status: _TechStatus.available,
    cost: 200,
  ),
  _TechNode(
    id: 'weapons',
    category: 'WAFFEN',
    name: 'Railgun Prototype',
    description: 'Experimentelle kinetische Waffe. Hoher Schaden.',
    level: 0,
    maxLevel: 3,
    status: _TechStatus.locked,
    cost: 500,
  ),
  _TechNode(
    id: 'ai',
    category: 'FLOTTEN-KI',
    name: 'Fleet AI Core',
    description: 'Autonom operierende Flotte nach Logik-Skript.',
    level: 0,
    maxLevel: 1,
    status: _TechStatus.locked,
    cost: 1000,
  ),
];

// ── Header ────────────────────────────────────────────────────────────────────

class _ResearchHeader extends StatelessWidget {
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
                'FORSCHUNG & ENTWICKLUNG',
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

class _ResourceBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.90),
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.30),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Resource(Icons.science_outlined, 'FORSCHUNG', '340', AppColors.primaryFixed),
          _Resource(Icons.diamond_outlined, 'KRISTALLE', '12', AppColors.secondaryFixedDim),
          _Resource(Icons.memory_outlined, 'SCHEMATA', '3', AppColors.tertiaryFixed),
        ],
      ),
    );
  }
}

class _Resource extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _Resource(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

// ── Tech Tree Widgets ─────────────────────────────────────────────────────────

class _TechRow extends StatelessWidget {
  final List<_TechNode> nodes;
  final _TechNode? selected;
  final ValueChanged<_TechNode> onSelect;

  const _TechRow({
    required this.nodes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (nodes.length == 1) {
      return Center(
        child: SizedBox(
          width: 280,
          child: _TechCard(
            node: nodes[0],
            isSelected: selected?.id == nodes[0].id,
            onTap: () => onSelect(nodes[0]),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: nodes.map((n) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _TechCard(
                node: n,
                isSelected: selected?.id == n.id,
                onTap: () => onSelect(n),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TechCard extends StatelessWidget {
  final _TechNode node;
  final bool isSelected;
  final VoidCallback onTap;

  const _TechCard({
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (node.status) {
      _TechStatus.unlocked => AppColors.primary,
      _TechStatus.available => AppColors.primary.withValues(alpha: 0.60),
      _TechStatus.locked => AppColors.outline.withValues(alpha: 0.50),
    };

    return GestureDetector(
      onTap: node.status != _TechStatus.locked ? onTap : null,
      child: Opacity(
        opacity: node.status == _TechStatus.locked ? 0.50 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: node.status == _TechStatus.unlocked
                ? AppColors.primary.withValues(alpha: 0.10)
                : AppColors.background,
            border: Border.all(
              color: isSelected ? AppColors.primary : statusColor,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: node.status == _TechStatus.unlocked
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.20),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: statusColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      node.category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: node.status == _TechStatus.unlocked
                                ? AppColors.onPrimary
                                : AppColors.onSurface.withValues(alpha: 0.70),
                            fontSize: 9,
                          ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      color: AppColors.background.withValues(alpha: 0.80),
                      child: node.status == _TechStatus.unlocked
                          ? Center(
                              child: Container(
                                width: 4,
                                height: 4,
                                color: AppColors.primaryFixedDim,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: node.status == _TechStatus.unlocked
                                ? AppColors.primaryFixed
                                : AppColors.onSurface,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (node.status == _TechStatus.unlocked)
                      Text(
                        'LVL MAX',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 9,
                            ),
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.science_outlined,
                              size: 10, color: AppColors.primaryFixed),
                          const SizedBox(width: 3),
                          Text(
                            '${node.cost} FP',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.primaryFixed,
                                  fontSize: 9,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Level indicator
              if (node.maxLevel > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: List.generate(node.maxLevel, (i) {
                      final filled = i < node.level;
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: i < node.maxLevel - 1
                              ? const EdgeInsets.only(right: 2)
                              : EdgeInsets.zero,
                          color: filled
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.15),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechConnector extends StatelessWidget {
  final bool active;
  const _TechConnector({required this.active});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 1,
        height: 40,
        color: active
            ? AppColors.primary.withValues(alpha: 0.70)
            : AppColors.outline.withValues(alpha: 0.30),
      ),
    );
  }
}

// ── Node Detail Panel ─────────────────────────────────────────────────────────

class _NodeDetail extends StatelessWidget {
  final _TechNode node;
  final VoidCallback onDismiss;
  final VoidCallback onResearch;

  const _NodeDetail({
    required this.node,
    required this.onDismiss,
    required this.onResearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.95),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                node.name.toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close, size: 16, color: AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            node.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 10),
          if (node.status == _TechStatus.available)
            GestureDetector(
              onTap: onResearch,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  color: AppColors.primary.withValues(alpha: 0.05),
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
                    Icon(Icons.science_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'ERFORSCHEN (${node.cost} FP)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 0.15,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else if (node.status == _TechStatus.locked)
            Text(
              'Vorhergehende Technologie erforderlich.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.outline,
                  ),
            ),
        ],
      ),
    );
  }
}
