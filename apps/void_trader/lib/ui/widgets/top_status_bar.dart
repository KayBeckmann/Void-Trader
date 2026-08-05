import 'package:flutter/material.dart';
import 'package:vt_physics/vt_physics.dart';

import 'hud_panel.dart';

/// Tag/Nacht-Zeit + Wetter auf einen Blick (Roadmap UI-02: eigenständiges
/// Panel statt Teil einer monolithischen HUD-Datei).
class TopStatusBar extends StatelessWidget {
  final bool isDay;
  final String timeLabel;
  final Weather weather;

  const TopStatusBar({
    super.key,
    required this.isDay,
    required this.timeLabel,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDay ? Icons.wb_sunny : Icons.nightlight_round,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(timeLabel, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(width: 10),
          Icon(_weatherIcon(weather), color: Colors.white70, size: 16),
          const SizedBox(width: 4),
          Text(
            _weatherLabel(weather),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
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
