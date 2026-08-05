import 'package:vt_content/vt_content.dart';

void main() {
  final workbench = buildingDefinitionFor(BuildingType.workbench);
  print('${workbench.name} kostet: ${workbench.buildCost}');
  print('Rezept "${basicComponentRecipe.name}": ${basicComponentRecipe.input} -> ${basicComponentRecipe.output}');
}
