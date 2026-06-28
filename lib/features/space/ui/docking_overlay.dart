import 'package:flutter/material.dart';
import '../../../core/domain/market.dart';
import '../../../core/domain/player_state.dart';
import '../../../core/domain/star_system.dart';
import 'market_screen.dart';

class DockingOverlay extends StatelessWidget {
  final Planet planet;
  final VoidCallback onUndock;
  final SystemMarket? market;
  final PlayerState? player;

  const DockingOverlay({
    super.key,
    required this.planet,
    required this.onUndock,
    this.market,
    this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      child: SafeArea(
        child: Column(
          children: [
            _Header(planet: planet),
            Expanded(
              child: _ServiceGrid(
                planetType: planet.type,
                onMarketOpen: (market != null && player != null)
                    ? () => _openMarket(context)
                    : null,
              ),
            ),
            _Footer(onUndock: onUndock),
          ],
        ),
      ),
    );
  }

  void _openMarket(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MarketScreen(
        market: market!,
        player: player!,
        onClose: () => Navigator.of(context).pop(),
      ),
    ));
  }
}

class _Header extends StatelessWidget {
  final Planet planet;
  const _Header({required this.planet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A237E))),
        color: Color(0xFF080820),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            planet.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _Tag(_typeLabel(planet.type), _typeColor(planet.type)),
              const SizedBox(width: 8),
              _Tag(planet.ownerFaction, const Color(0xFF455A64)),
              if (planet.isPlayerBase) ...[
                const SizedBox(width: 8),
                const _Tag('HEIMATBASIS', Color(0xFF006064)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(String t) => switch (t) {
        'industrial' => 'Industrie',
        'trade' => 'Handel',
        'colony' => 'Kolonie',
        'habitat' => 'Habitat',
        'mining' => 'Bergbau',
        _ => t,
      };

  Color _typeColor(String t) => switch (t) {
        'industrial' => const Color(0xFF37474F),
        'trade' => const Color(0xFF4A4000),
        'colony' => const Color(0xFF1B5E20),
        'habitat' => const Color(0xFF01579B),
        'mining' => const Color(0xFF3E2723),
        _ => const Color(0xFF263238),
      };
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  final String planetType;
  final VoidCallback? onMarketOpen;
  const _ServiceGrid({required this.planetType, this.onMarketOpen});

  @override
  Widget build(BuildContext context) {
    final services = _servicesFor(planetType);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: services.map((s) => _ServiceTile(
          label: s.label,
          icon: s.icon,
          available: s.available,
          onTap: s.label == 'Markt' ? onMarketOpen : null,
        )).toList(),
      ),
    );
  }

  List<_ServiceDef> _servicesFor(String type) => [
        _ServiceDef('Markt', Icons.store, true),
        _ServiceDef('Werft', Icons.build, type == 'industrial'),
        _ServiceDef('Reparatur', Icons.healing, true),
        _ServiceDef('Forschung', Icons.science, type == 'habitat'),
        _ServiceDef('Mission', Icons.assignment, true),
        _ServiceDef('Fracht', Icons.inventory_2, type == 'trade' || type == 'industrial'),
      ];
}

class _ServiceDef {
  final String label;
  final IconData icon;
  final bool available;
  const _ServiceDef(this.label, this.icon, this.available);
}

class _ServiceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool available;
  final VoidCallback? onTap;

  const _ServiceTile({
    required this.label,
    required this.icon,
    required this.available,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: available ? const Color(0xFF0D1B2A) : const Color(0xFF090909),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: available ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: available ? const Color(0xFF1A3A5C) : const Color(0xFF1A1A1A),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: available ? const Color(0xFF4FC3F7) : Colors.grey[800], size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: available ? Colors.white : Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onUndock;
  const _Footer({required this.onUndock});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1A237E))),
        color: Color(0xFF080820),
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.rocket_launch),
        label: const Text('ABDOCKEN', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: onUndock,
      ),
    );
  }
}
