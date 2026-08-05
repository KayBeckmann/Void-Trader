import 'package:vt_physics/vt_physics.dart';

void main() {
  final grid = FluidGrid(4, 1);
  grid.setGroundHeight(0, 0, 2);
  grid.setGroundHeight(1, 0, 0);
  grid.addWater(0, 0, 1);

  for (var i = 0; i < 5; i++) {
    grid.step();
  }

  print('Wasserstand nach 5 Schritten: ${grid.cellAt(1, 0).waterLevel}');
}
