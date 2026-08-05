import 'package:test/test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';

void main() {
  group('basicComponentRecipe', () {
    test('produziert component aus stone + ore', () {
      expect(basicComponentRecipe.output, Resource.component);
      expect(basicComponentRecipe.input, {Resource.stone: 2, Resource.ore: 1});
      expect(basicComponentRecipe.outputAmount, 1);
    });

    test('lässt sich direkt auf ein Inventory anwenden', () {
      final inventory = Inventory();
      inventory.add(Resource.stone, 2);
      inventory.add(Resource.ore, 1);

      inventory.craft(
        basicComponentRecipe.input,
        basicComponentRecipe.output,
        outputAmount: basicComponentRecipe.outputAmount,
      );

      expect(inventory.count(Resource.component), 1);
      expect(inventory.count(Resource.stone), 0);
      expect(inventory.count(Resource.ore), 0);
    });
  });
}
