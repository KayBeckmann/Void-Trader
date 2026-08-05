import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_npc/vt_npc.dart';
import 'package:void_trader/game/npc_component.dart';

void main() {
  group('NpcComponent.colorForActivity', () {
    test('liefert für jede NpcActivity eine Farbe', () {
      for (final activity in NpcActivity.values) {
        expect(NpcComponent.colorForActivity(activity), isNotNull);
      }
    });
  });

  group('NpcComponent Konstruktion', () {
    test('hält eine Referenz auf den übergebenen Npc', () {
      final npc = Npc(id: 'test', type: NpcType.colonist);
      final component = NpcComponent(npc: npc, position: Vector2.zero());
      expect(component.npc, same(npc));
    });
  });
}
