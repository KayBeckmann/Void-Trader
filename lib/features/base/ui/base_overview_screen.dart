import 'package:flutter/material.dart';
import '../../../core/data/building_repository.dart';
import '../../../core/domain/base_state.dart';
import '../../../core/domain/building.dart';
import '../../../core/domain/commodity.dart';
import '../../../core/domain/crew.dart';

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

class _BaseOverviewScreenState extends State<BaseOverviewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  BuildingDef? _selectedBuild;
  String? _message;
  List<BuildingDef> _buildableDefs = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadBuildable();
  }

  Future<void> _loadBuildable() async {
    final defs = await BuildingRepository.loadAll();
    if (mounted) setState(() => _buildableDefs = defs.where((d) => !d.isStub).toList());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.base;
    return Material(
      color: const Color(0xFF050A14),
      child: Column(
        children: [
          _BaseHeader(base: base, onClose: widget.onClose),
          _EnergyBar(produced: base.energyProduced, consumed: base.energyConsumed),
          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFF69FF47),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            tabs: const [Tab(text: 'KARTE'), Tab(text: 'BAUEN'), Tab(text: 'CREW')],
          ),
          if (_message != null)
            Container(
              color: const Color(0xFF0D2010),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Text(_message!, style: const TextStyle(color: Color(0xFF69FF47), fontSize: 12)),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _GridView(
                  base: base,
                  selectedDef: _selectedBuild,
                  onTileTap: _handleTileTap,
                ),
                _BuildMenu(
                  defs: _buildableDefs,
                  selected: _selectedBuild,
                  onSelect: (d) => setState(() {
                    _selectedBuild = d;
                    _tabs.animateTo(0);
                    _message = 'Wähle einen Platz auf der Karte für "${d.name}"';
                  }),
                  playerInventory: widget.playerInventory,
                ),
                _CrewPanel(
                  base: base,
                  onHire: (role) => setState(() {
                    if (widget.playerCredits >= 500) {
                      base.hireCrew(role);
                      widget.onCreditsChanged();
                    } else {
                      _message = 'Nicht genug Credits (500 ₵ Einstellungsgebühr)';
                    }
                  }),
                ),
              ],
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
        setState(() => _message = '${existing.def.name} — Energie: ${existing.def.energyBalance > 0 ? '+' : ''}${existing.def.energyBalance}');
      }
      return;
    }

    final success = widget.base.placeBuilding(_selectedBuild!, gx, gy, widget.playerInventory);
    setState(() {
      if (success) {
        _message = '${_selectedBuild!.name} gebaut!';
        _selectedBuild = null;
      } else {
        _message = 'Kein Platz oder fehlende Materialien.';
      }
    });
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _BaseHeader extends StatelessWidget {
  final BaseState base;
  final VoidCallback onClose;
  const _BaseHeader({required this.base, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF080820),
        border: Border(bottom: BorderSide(color: Color(0xFF1A237E))),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_work, color: Color(0xFF69FF47), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HEIMATBASIS', style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 3)),
                Text(base.planetName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Tag ${base.dayCount}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(base.isNight ? '🌙 Nacht' : '☀ Tag', style: TextStyle(color: base.isNight ? const Color(0xFF7C4DFF) : const Color(0xFFFFD740), fontSize: 11)),
            ],
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: onClose),
        ],
      ),
    );
  }
}

// ── Energy bar ────────────────────────────────────────────────────────────────

class _EnergyBar extends StatelessWidget {
  final double produced;
  final double consumed;
  const _EnergyBar({required this.produced, required this.consumed});

  @override
  Widget build(BuildContext context) {
    final balance = produced - consumed;
    final color = balance >= 0 ? const Color(0xFF69FF47) : const Color(0xFFFF5252);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF080820),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFFFFD740), size: 16),
          const SizedBox(width: 6),
          Text('Energie: ${produced.toStringAsFixed(0)} erzeugt / ${consumed.toStringAsFixed(0)} verbraucht',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const Spacer(),
          Text('${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(0)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Grid view ─────────────────────────────────────────────────────────────────

class _GridView extends StatelessWidget {
  final BaseState base;
  final BuildingDef? selectedDef;
  final void Function(int, int) onTileTap;

  const _GridView({required this.base, this.selectedDef, required this.onTileTap});

  @override
  Widget build(BuildContext context) {
    const tileSize = 36.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(BaseState.gridHeight, (gy) {
              return Row(
                children: List.generate(BaseState.gridWidth, (gx) {
                  return _Tile(
                    base: base,
                    gx: gx,
                    gy: gy,
                    size: tileSize,
                    onTap: () => onTileTap(gx, gy),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final BaseState base;
  final int gx, gy;
  final double size;
  final VoidCallback onTap;

  const _Tile({required this.base, required this.gx, required this.gy, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final building = base.buildingAt(gx, gy);
    final isNode = base.resourceNodes.any((n) => n.gridX == gx && n.gridY == gy);
    final cellId = base.cellAt(gx, gy);
    // Only render the top-left cell of a multi-tile building
    final isAnchor = building != null && building.gridX == gx && building.gridY == gy;
    final isOccupied = cellId != null && !isAnchor;

    if (isOccupied) {
      return SizedBox(width: size + 1, height: size + 1);
    }

    Color bgColor = const Color(0xFF0A1520);
    Color borderColor = const Color(0xFF1A2A3A);
    Widget? icon;

    if (isNode) {
      bgColor = const Color(0xFF1A2A0A);
      borderColor = const Color(0xFF2A4A1A);
      icon = const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 10);
    }

    if (building != null && isAnchor) {
      bgColor = building.isActive ? const Color(0xFF0D2040) : const Color(0xFF1A0A0A);
      borderColor = building.isActive ? const Color(0xFF1A3A5C) : const Color(0xFF3A1A1A);
      icon = Icon(
        _iconFor(building.def.category),
        color: building.isActive ? const Color(0xFF4FC3F7) : const Color(0xFF607D8B),
        size: building.def.gridSize == 2 ? 26 : 18,
      );
    }

    final actualSize = (size + 1) * (building?.def.gridSize ?? 1) - 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: building?.def.gridSize == 2 ? actualSize : size,
        height: building?.def.gridSize == 2 ? actualSize : size,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 0.8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: icon != null ? Center(child: icon) : null,
      ),
    );
  }

  IconData _iconFor(BuildingCategory cat) => switch (cat) {
        BuildingCategory.energy => Icons.bolt,
        BuildingCategory.extraction => Icons.construction,
        BuildingCategory.production => Icons.factory,
        BuildingCategory.storage => Icons.warehouse,
        BuildingCategory.defense => Icons.shield,
        BuildingCategory.special => Icons.science,
      };
}

// ── Build menu ────────────────────────────────────────────────────────────────

class _BuildMenu extends StatelessWidget {
  final List<BuildingDef> defs;
  final BuildingDef? selected;
  final ValueChanged<BuildingDef> onSelect;
  final Inventory playerInventory;

  const _BuildMenu({
    required this.defs,
    required this.selected,
    required this.onSelect,
    required this.playerInventory,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: defs.length,
      separatorBuilder: (context, index) => const Divider(color: Color(0xFF1A2A3A), height: 1),
      itemBuilder: (_, i) {
        final def = defs[i];
        final isSelected = selected?.id == def.id;
        final canAfford = def.buildCost.every(
          (c) => playerInventory.quantityOf(c.commodityId) >= c.quantity,
        );
        return InkWell(
          onTap: () => onSelect(def),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: canAfford ? (isSelected ? const Color(0xFF0D2040) : Colors.transparent) : const Color(0xFF0A0A0A),
            child: Row(
              children: [
                Icon(_catIcon(def.category), color: canAfford ? const Color(0xFF4FC3F7) : Colors.grey[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(def.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(def.description, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: def.buildCost.map((c) {
                          final have = playerInventory.quantityOf(c.commodityId);
                          return Text(
                            '${c.commodityId}: $have/${c.quantity}',
                            style: TextStyle(
                              color: have >= c.quantity ? const Color(0xFF69FF47) : const Color(0xFFFF5252),
                              fontSize: 10,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      def.energyBalance >= 0 ? '+${def.energyBalance.toStringAsFixed(0)} ⚡' : '${def.energyBalance.toStringAsFixed(0)} ⚡',
                      style: TextStyle(
                        color: def.energyBalance >= 0 ? const Color(0xFFFFD740) : const Color(0xFFFF8F00),
                        fontSize: 11,
                      ),
                    ),
                    if (!canAfford)
                      const Text('Fehlt Material', style: TextStyle(color: Color(0xFFFF5252), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _catIcon(BuildingCategory c) => switch (c) {
        BuildingCategory.energy => Icons.bolt,
        BuildingCategory.extraction => Icons.construction,
        BuildingCategory.production => Icons.factory,
        BuildingCategory.storage => Icons.warehouse,
        BuildingCategory.defense => Icons.shield,
        BuildingCategory.special => Icons.science,
      };
}

// ── Crew panel ────────────────────────────────────────────────────────────────

class _CrewPanel extends StatelessWidget {
  final BaseState base;
  final ValueChanged<CrewRole> onHire;
  const _CrewPanel({required this.base, required this.onHire});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Eingestellt: ${base.crew.length} Crew  ·  Tageskosten: ${base.dailyWageCost.toStringAsFixed(0)} ₵',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        _SectionTitle('EINSTELLEN (500 ₵)'),
        ...CrewRole.values.map((role) => _HireButton(role: role, onHire: onHire)),
        const SizedBox(height: 24),
        _SectionTitle('AKTUELLE CREW'),
        if (base.crew.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Noch keine Crew angeheuert.', style: TextStyle(color: Colors.white38)),
          )
        else
          ...base.crew.map((m) => _CrewRow(member: m)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 10, letterSpacing: 2)),
      );
}

class _HireButton extends StatelessWidget {
  final CrewRole role;
  final ValueChanged<CrewRole> onHire;
  const _HireButton({required this.role, required this.onHire});

  @override
  Widget build(BuildContext context) {
    final wages = {CrewRole.worker: 80, CrewRole.researcher: 200, CrewRole.pilot: 150, CrewRole.guard: 120};
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1A3A5C)),
          foregroundColor: Colors.white70,
        ),
        onPressed: () => onHire(role),
        child: Row(
          children: [
            Icon(_roleIcon(role), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_roleName(role))),
            Text('${wages[role]} ₵/Tag', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  IconData _roleIcon(CrewRole r) => switch (r) {
        CrewRole.worker => Icons.hardware,
        CrewRole.researcher => Icons.science,
        CrewRole.pilot => Icons.flight,
        CrewRole.guard => Icons.security,
      };

  String _roleName(CrewRole r) => switch (r) {
        CrewRole.worker => 'Arbeiter  (+20% Produktion)',
        CrewRole.researcher => 'Forscher  (für Techtree)',
        CrewRole.pilot => 'Pilot  (für Flotte)',
        CrewRole.guard => 'Wache  (+Verteidigung)',
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
          Text(member.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 8),
          Text(member.roleLabel, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const Spacer(),
          Text(member.isAssigned ? '● Zugewiesen' : '○ Frei',
              style: TextStyle(color: member.isAssigned ? const Color(0xFF69FF47) : Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
