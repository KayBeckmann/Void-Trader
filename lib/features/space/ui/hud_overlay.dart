import 'package:flutter/material.dart';
import '../../../core/domain/ship_stats.dart';

class HudOverlay extends StatelessWidget {
  final ShipStats stats;
  final String systemName;

  const HudOverlay({
    super.key,
    required this.stats,
    required this.systemName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 160, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SystemLabel(systemName),
          const SizedBox(height: 8),
          _Bar(
            label: 'SCHILD',
            value: stats.shieldPercent,
            color: const Color(0xFF4FC3F7),
          ),
          const SizedBox(height: 4),
          _Bar(
            label: 'HÜLLE',
            value: stats.hullPercent,
            color: _hullColor(stats.hullPercent),
          ),
        ],
      ),
    );
  }

  Color _hullColor(double pct) {
    if (pct > 0.5) return const Color(0xFF69FF47);
    if (pct > 0.25) return const Color(0xFFFFD740);
    return const Color(0xFFFF5252);
  }
}

class _SystemLabel extends StatelessWidget {
  final String name;
  const _SystemLabel(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF1A3A5C)),
      ),
      child: Text(
        name.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF90CAF9),
          fontSize: 11,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _Bar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white12),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 32,
          child: Text(
            '${(value * 100).round()}%',
            style: TextStyle(color: color, fontSize: 10),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
