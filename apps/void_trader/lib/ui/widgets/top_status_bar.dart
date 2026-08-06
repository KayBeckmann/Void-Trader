import 'package:flutter/material.dart';
import 'package:vt_physics/vt_physics.dart';

import '../design_tokens.dart';
import 'hud_panel.dart';

/// Obere Statusleiste (Roadmap HUD-11: "TopStatusBar V2") — segmentierte,
/// (fast) vollbreite Leiste am oberen Bildschirmrand statt eines kompakten
/// Textblocks: Zeit/Wetter/z-Ebene/Credits/Fracht-Kurzstatus, jedes Segment
/// mit eigenem Icon und Akzentfarbe.
class TopStatusBar extends StatelessWidget {
  final bool isDay;
  final String timeLabel;
  final Weather weather;
  final String zLevelLabel;
  final int credits;
  final int shipCargoCount;

  const TopStatusBar({
    super.key,
    required this.isDay,
    required this.timeLabel,
    required this.weather,
    required this.zLevelLabel,
    required this.credits,
    required this.shipCargoCount,
  });

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusSegment(
            icon: isDay ? Icons.wb_sunny : Icons.nightlight_round,
            label: timeLabel,
            color: VtColors.accentAmber,
          ),
          const _SegmentDivider(),
          _StatusSegment(
            icon: _weatherIcon(weather),
            label: _weatherLabel(weather),
            color: VtColors.accentCyan,
          ),
          const _SegmentDivider(),
          _StatusSegment(
            icon: Icons.layers_outlined,
            label: zLevelLabel,
            color: VtColors.accentCyan,
          ),
          const _SegmentDivider(),
          _StatusSegment(
            icon: Icons.paid_outlined,
            label: '$credits Cr',
            color: VtColors.accentGreen,
          ),
          const _SegmentDivider(),
          _StatusSegment(
            icon: Icons.local_shipping_outlined,
            label: '$shipCargoCount Fracht',
            color: VtColors.accentCyan,
          ),
        ],
      ),
    );
  }

  static IconData _weatherIcon(Weather weather) {
    switch (weather) {
      case Weather.clear:
        return Icons.wb_sunny_outlined;
      case Weather.cloudy:
        return Icons.cloud_outlined;
      case Weather.rain:
        return Icons.grain;
      case Weather.storm:
        return Icons.thunderstorm_outlined;
    }
  }

  static String _weatherLabel(Weather weather) {
    switch (weather) {
      case Weather.clear:
        return 'Klar';
      case Weather.cloudy:
        return 'Bewölkt';
      case Weather.rain:
        return 'Regen';
      case Weather.storm:
        return 'Sturm';
    }
  }
}

class _StatusSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusSegment({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: VtSpacing.xs),
        Text(
          label,
          style: TextStyle(color: VtColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Dünne vertikale Trennlinie zwischen Segmenten — "segmentierte Bereiche
/// statt Textblock" laut Roadmap-Vorgabe.
class _SegmentDivider extends StatelessWidget {
  const _SegmentDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VtSpacing.md),
      child: Container(width: 1, height: 16, color: VtColors.panelBorder),
    );
  }
}
