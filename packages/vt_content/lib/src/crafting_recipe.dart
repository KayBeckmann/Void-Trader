import 'package:vt_core/vt_core.dart';

/// Ein Umwandlungs-Rezept für die Produktionskette (Roadmap Phase 4:
/// "Holz/Stein/Erz/Wasser → Lager → Werkbank/Schmelzer → Bauteile").
class CraftingRecipe {
  final String name;
  final Map<Resource, int> input;
  final Resource output;
  final int outputAmount;

  const CraftingRecipe({
    required this.name,
    required this.input,
    required this.output,
    this.outputAmount = 1,
  });
}

/// Erstes Rezept der Produktionskette V1: Stein + Erz an der Werkbank zu
/// einem Bauteil verarbeiten.
const CraftingRecipe basicComponentRecipe = CraftingRecipe(
  name: 'Bauteil',
  input: {Resource.stone: 2, Resource.ore: 1},
  output: Resource.component,
);
