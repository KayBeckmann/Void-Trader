import 'package:flame/game.dart';
import 'package:vt_physics/vt_physics.dart';
import 'package:vt_world/vt_world.dart';

import 'debug_map_component.dart';

/// Root Flame game.
///
/// Aktuell zeigt es die [DebugMapComponent] (Tiles + Wasserzustand eines
/// Chunks) — erstes sichtbares Ergebnis von Phase 1 der Reboot-Roadmap.
/// Spielerfigur/Kamera und echte Sprites folgen in den nächsten Schritten.
class VoidTraderGame extends FlameGame {
  VoidTraderGame({int seed = 1}) : world = World(seed);

  final World world;
  late final FluidGrid debugFluidGrid;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    debugFluidGrid = FluidGrid(Chunk.size, Chunk.size);
    // Demo-Wasserquelle für den Debug-Screen. Phase 3 koppelt das Fluid-Grid
    // an echte Gelände-Höhen aus vt_world statt an ein leeres Demo-Grid.
    debugFluidGrid.addWater(4, 4, 6);

    add(
      DebugMapComponent(
        world: world,
        chunkCoord: const ChunkCoord(0, 0),
        z: ZLevel.surface,
        fluidGrid: debugFluidGrid,
      ),
    );
  }
}
