import 'dart:ui';

import 'package:flame/components.dart';
import 'package:vt_npc/vt_npc.dart';

/// Visuelle Darstellung eines [Npc] in der Debug-Karte (Phase 5).
///
/// Rein passiv: Bewegung/Pfadfindung gibt es noch nicht, die Komponente
/// zeigt nur den inneren Zustand (aktuelle Aktivität) über die Farbe an.
/// Der eigentliche NPC-Zustand lebt komplett in vt_npc (Dart-Core) und wird
/// von VoidTraderGame getickt — diese Komponente liest nur mit.
class NpcComponent extends PositionComponent {
  final Npc npc;

  NpcComponent({required this.npc, required Vector2 position})
    : super(position: position, size: Vector2.all(10), anchor: Anchor.center);

  final Paint _paint = Paint();

  @override
  void render(Canvas canvas) {
    _paint.color = colorForActivity(npc.activity);
    canvas.drawRect(size.toRect(), _paint);
  }

  /// Debug-Farbe je Aktivität. Wird durch echte Pixel-Art/Animationen in
  /// einer späteren Phase ersetzt.
  static Color colorForActivity(NpcActivity activity) {
    switch (activity) {
      case NpcActivity.idle:
        return const Color(0xFFBDBDBD);
      case NpcActivity.working:
        return const Color(0xFF03A9F4);
      case NpcActivity.eating:
        return const Color(0xFFFF7043);
      case NpcActivity.drinking:
        return const Color(0xFF29B6F6);
      case NpcActivity.sleeping:
        return const Color(0xFF7E57C2);
    }
  }
}
