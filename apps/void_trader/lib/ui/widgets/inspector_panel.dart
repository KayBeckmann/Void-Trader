import 'package:flutter/material.dart';

import '../tile_inspector_info.dart';
import 'hud_panel.dart';

/// Zeigt, was am gerade ausgewählten/anvisierten Tile möglich ist — und
/// warum nicht, falls eine Aktion gesperrt ist (Roadmap UI-02/UI-03:
/// "Inspector zeigt verständliche deutsche Labels").
class InspectorPanel extends StatelessWidget {
  final TileInspectorInfo info;

  const InspectorPanel({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            info.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          for (final detail in info.details)
            Text(detail, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          for (final action in info.actions) _ActionLine(action: action),
        ],
      ),
    );
  }
}

class _ActionLine extends StatelessWidget {
  final InspectorActionInfo action;

  const _ActionLine({required this.action});

  @override
  Widget build(BuildContext context) {
    final label = action.keyHint.isEmpty ? action.label : '${action.label} (${action.keyHint})';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            action.available ? Icons.check_circle_outline : Icons.block,
            color: action.available ? Colors.lightGreenAccent : Colors.redAccent,
            size: 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  if (!action.available && action.blockedReason != null)
                    TextSpan(
                      text: ' — ${action.blockedReason}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
