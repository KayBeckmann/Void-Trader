import 'package:flame/game.dart';
import 'package:vt_physics/vt_physics.dart';
// Alias nötig: FlameGame definiert selbst einen `world`-Getter/Kamera-World —
// Namenskollision mit vt_world.World.
import 'package:vt_world/vt_world.dart' as vt_world;

import 'debug_map_component.dart';

/// Root Flame game.
///
/// Aktuell zeigt es die [DebugMapComponent] (Tiles + Wasserzustand eines
/// Chunks) — erstes sichtbares Ergebnis von Phase 1 der Reboot-Roadmap.
/// Spielerfigur/Kamera und echte Sprites folgen in den nächsten Schritten.
class VoidTraderGame extends FlameGame {
  VoidTraderGame({int seed = 1}) : simulationWorld = vt_world.World(seed);

  final vt_world.World simulationWorld;
  late final FluidGrid debugFluidGrid;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    debugFluidGrid = FluidGrid(vt_world.Chunk.size, vt_world.Chunk.size);
    // Demo-Wasserquelle für den Debug-Screen. Phase 3 koppelt das Fluid-Grid
    // an echte Gelände-Höhen aus vt_world statt an ein leeres Demo-Grid.
    debugFluidGrid.addWater(4, 4, 6);

    add(
      DebugMapComponent(
        gameWorld: simulationWorld,
        chunkCoord: const vt_world.ChunkCoord(0, 0),
        z: vt_world.ZLevel.surface,
        fluidGrid: debugFluidGrid,
      ),
    );
  }
}
