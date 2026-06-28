import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/domain/player_state.dart';
import '../../../core/domain/star_system.dart';

class PlanetScanScreen extends StatefulWidget {
  final Planet planet;
  final PlayerState player;
  final VoidCallback onClaim;
  final VoidCallback onClose;

  const PlanetScanScreen({
    super.key,
    required this.planet,
    required this.player,
    required this.onClaim,
    required this.onClose,
  });

  @override
  State<PlanetScanScreen> createState() => _PlanetScanScreenState();
}

class _PlanetScanScreenState extends State<PlanetScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanAnim;
  bool _scanComplete = false;
  late final _ScanData _data;

  @override
  void initState() {
    super.initState();
    _data = _ScanData.generate(widget.planet);
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward().then((_) {
        if (mounted) setState(() => _scanComplete = true);
      });
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    super.dispose();
  }

  bool get _canClaim {
    final scanCost = 500.0;
    return !widget.planet.isPlayerBase &&
        widget.player.credits >= scanCost &&
        widget.player.reputationWith(widget.planet.ownerFaction) >= -30;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF050A14),
      child: SafeArea(
        child: Column(
          children: [
            _ScanHeader(planet: widget.planet, onClose: widget.onClose),
            Expanded(
              child: _scanComplete
                  ? _ScanResults(data: _data, planet: widget.planet)
                  : _ScanProgress(animation: _scanAnim),
            ),
            if (_scanComplete)
              _ClaimFooter(
                canClaim: _canClaim,
                isPlayerBase: widget.planet.isPlayerBase,
                repBlock: widget.player.reputationWith(widget.planet.ownerFaction) < -30,
                onClaim: widget.onClaim,
                onClose: widget.onClose,
              ),
          ],
        ),
      ),
    );
  }
}

class _ScanHeader extends StatelessWidget {
  final Planet planet;
  final VoidCallback onClose;
  const _ScanHeader({required this.planet, required this.onClose});

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
          const Icon(Icons.radar, color: Color(0xFF4FC3F7), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PLANETEN-SCAN', style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 3)),
                Text(planet.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: onClose),
        ],
      ),
    );
  }
}

class _ScanProgress extends StatelessWidget {
  final AnimationController animation;
  const _ScanProgress({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) => SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: animation.value,
                strokeWidth: 3,
                color: const Color(0xFF4FC3F7),
                backgroundColor: const Color(0xFF1A3A5C),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Scanne Planetenoberfläche…', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ScanResults extends StatelessWidget {
  final _ScanData data;
  final Planet planet;
  const _ScanResults({required this.data, required this.planet});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ScanSection('Rohstoff-Vorkommen', [
          for (final r in data.resources) _ScanRow(r.label, r.rating, r.color),
        ]),
        const SizedBox(height: 16),
        _ScanSection('Umgebungsbedingungen', [
          _ScanRow('Klima', data.climate, _climateColor(data.climate)),
          _ScanRow('Tektonik', data.tectonic, _ratingColor(data.tectonic)),
          _ScanRow('Strahlung', data.radiation, _inverseColor(data.radiation)),
        ]),
        const SizedBox(height: 16),
        _ScanSection('Bedrohungslage', [
          _ScanRow('Marauder-Aktivität', data.threat, _inverseColor(data.threat)),
          _ScanRow('Piratenpräsenz', data.piracy, _inverseColor(data.piracy)),
        ]),
        const SizedBox(height: 16),
        _ScanSection('Politik & Lizenz', [
          _InfoRow('Fraktion', planet.ownerFaction),
          _InfoRow('Claim-Kosten', '500 ₵ + Ruf ≥ −30'),
        ]),
      ],
    );
  }

  Color _climateColor(String s) => switch (s) {
        'Gemäßigt' => const Color(0xFF81C784),
        'Arktisch' || 'Heiß' => const Color(0xFFFFD740),
        _ => const Color(0xFFFF5252),
      };

  Color _ratingColor(String s) => switch (s) {
        'Stabil' || 'Niedrig' => const Color(0xFF81C784),
        'Mittel' => const Color(0xFFFFD740),
        _ => const Color(0xFFFF5252),
      };

  Color _inverseColor(String s) => switch (s) {
        'Niedrig' => const Color(0xFF81C784),
        'Mittel' => const Color(0xFFFFD740),
        _ => const Color(0xFFFF5252),
      };
}

class _ScanSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ScanSection(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF080820),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1A3A5C)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ScanRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ScanRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(value, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ClaimFooter extends StatelessWidget {
  final bool canClaim;
  final bool isPlayerBase;
  final bool repBlock;
  final VoidCallback onClaim;
  final VoidCallback onClose;

  const _ClaimFooter({
    required this.canClaim,
    required this.isPlayerBase,
    required this.repBlock,
    required this.onClaim,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF080820),
        border: Border(top: BorderSide(color: Color(0xFF1A237E))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPlayerBase)
            const Text('Dies ist bereits deine Heimatbasis.', style: TextStyle(color: Color(0xFF69FF47), fontSize: 12))
          else if (repBlock)
            const Text('Ruf zu niedrig — Claim verweigert.', style: TextStyle(color: Color(0xFFFF5252), fontSize: 12)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: canClaim ? const Color(0xFF1B5E20) : Colors.grey[900],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.flag),
            label: Text(isPlayerBase ? 'BEREITS BEANSPRUCHT' : 'HEIMATBASIS GRÜNDEN (500 ₵)'),
            onPressed: canClaim ? onClaim : null,
          ),
        ],
      ),
    );
  }
}

// ── Scan data model ──────────────────────────────────────────────────────────

class _ResourceRating {
  final String label;
  final String rating;
  final Color color;
  const _ResourceRating(this.label, this.rating, this.color);
}

class _ScanData {
  final List<_ResourceRating> resources;
  final String climate;
  final String tectonic;
  final String radiation;
  final String threat;
  final String piracy;

  const _ScanData({
    required this.resources,
    required this.climate,
    required this.tectonic,
    required this.radiation,
    required this.threat,
    required this.piracy,
  });

  static _ScanData generate(Planet planet) {
    final rng = math.Random(planet.id.hashCode);
    final ratings = ['Niedrig', 'Mittel', 'Hoch', 'Sehr hoch'];
    final climates = ['Gemäßigt', 'Arktisch', 'Heiß', 'Toxisch'];
    final tectonics = ['Stabil', 'Mittel', 'Aktiv'];

    Color ratingColor(String r) => switch (r) {
          'Niedrig' => const Color(0xFF607D8B),
          'Mittel' => const Color(0xFFFFD740),
          'Hoch' => const Color(0xFF81C784),
          'Sehr hoch' => const Color(0xFF69FF47),
          _ => Colors.white,
        };

    return _ScanData(
      resources: [
        _ResourceRating('Eisenerz', ratings[rng.nextInt(4)], ratingColor(ratings[rng.nextInt(4)])),
        _ResourceRating('Wassereis', ratings[rng.nextInt(4)], ratingColor(ratings[rng.nextInt(4)])),
        _ResourceRating('Organik', ratings[rng.nextInt(4)], ratingColor(ratings[rng.nextInt(4)])),
        _ResourceRating('Kristalle', ratings[rng.nextInt(4)], ratingColor(ratings[rng.nextInt(4)])),
      ],
      climate: climates[rng.nextInt(climates.length)],
      tectonic: tectonics[rng.nextInt(tectonics.length)],
      radiation: ratings[rng.nextInt(4)],
      threat: ratings[rng.nextInt(4)],
      piracy: planet.ownerFaction == 'npc.pirates' ? 'Hoch' : ratings[rng.nextInt(3)],
    );
  }
}
