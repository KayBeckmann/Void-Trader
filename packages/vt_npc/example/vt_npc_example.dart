import 'package:vt_npc/vt_npc.dart';

void main() {
  final npc = Npc(id: 'npc-1', type: NpcType.colonist);
  npc.tick(60, isDaytime: true);
  print('Aktivität: ${npc.activity}, Hunger: ${npc.needs.hunger}');
}
