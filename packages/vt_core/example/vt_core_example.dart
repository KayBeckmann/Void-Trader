import 'package:vt_core/vt_core.dart';

void main() {
  final inventory = Inventory();
  inventory.add(Resource.stone, 5);
  print('Stein im Inventar: ${inventory.count(Resource.stone)}');
}
