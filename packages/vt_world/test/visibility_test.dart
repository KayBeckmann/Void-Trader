import 'package:test/test.dart';
import 'package:vt_world/vt_world.dart';

void main() {
  group('ExplorationTracker (Roadmap FOW-01)', () {
    test('alles ist unseen, solange nichts entdeckt wurde', () {
      final tracker = ExplorationTracker();
      expect(tracker.stateAt(0, 0), VisibilityState.unseen);
      expect(tracker.discoveredCount, 0);
    });

    test('update() macht Tiles visible und merkt sie sich als entdeckt', () {
      final tracker = ExplorationTracker();
      tracker.update({(x: 0, y: 0), (x: 1, y: 0)});

      expect(tracker.stateAt(0, 0), VisibilityState.visible);
      expect(tracker.stateAt(1, 0), VisibilityState.visible);
      expect(tracker.stateAt(5, 5), VisibilityState.unseen);
      expect(tracker.discoveredCount, 2);
    });

    test('Tiles, die nicht mehr sichtbar sind, bleiben als seenButNotVisible bekannt', () {
      final tracker = ExplorationTracker();
      tracker.update({(x: 0, y: 0), (x: 1, y: 0)});
      tracker.update({(x: 0, y: 0)}); // (1,0) nicht mehr aktuell sichtbar

      expect(tracker.stateAt(0, 0), VisibilityState.visible);
      expect(tracker.stateAt(1, 0), VisibilityState.seenButNotVisible);
      expect(tracker.stateAt(9, 9), VisibilityState.unseen);
      // Entdeckt bleibt entdeckt, auch wenn gerade nicht sichtbar.
      expect(tracker.discoveredCount, 2);
    });
  });

  group('computeFieldOfView (Roadmap FOW-02)', () {
    test('der Ursprung selbst ist immer sichtbar', () {
      final world = World(1);
      final visible = computeFieldOfView(
        world: world,
        originX: 0,
        originY: 0,
        z: ZLevel.surface,
        facingX: 0,
        facingY: 1,
      );
      expect(visible, contains((x: 0, y: 0)));
    });

    test('Nahbereich ist auch entgegen der Blickrichtung sichtbar', () {
      final world = World(1);
      // Blick nach Norden (facingY < 0), Nahbereich 2 -> Tile direkt
      // südlich (hinter dem Spieler) sollte trotzdem sichtbar sein.
      final visible = computeFieldOfView(
        world: world,
        originX: 0,
        originY: 0,
        z: ZLevel.surface,
        facingX: 0,
        facingY: -1,
        nearRadius: 2,
        viewRadius: 8,
      );
      expect(visible, contains((x: 0, y: 1)));
    });

    test('Tiles weit entgegen der Blickrichtung, außerhalb des Nahbereichs, sind unsichtbar', () {
      final world = World(1);
      // Weg in beide Richtungen explizit begehbar/sichtfrei setzen, damit
      // der Test nur die Kegel-/Winkel-Logik prüft, nicht zufällige
      // Sichtblocker aus der Weltgenerierung.
      for (var y = -8; y <= 8; y++) {
        world.setTileAt(0, y, ZLevel.surface, const Tile(TileType.grass));
      }
      final visible = computeFieldOfView(
        world: world,
        originX: 0,
        originY: 0,
        z: ZLevel.surface,
        facingX: 0,
        facingY: -1, // Blick nach Norden
        nearRadius: 1,
        viewRadius: 8,
        fieldOfViewDegrees: 120,
      );
      // Direkt hinter dem Spieler, weit außerhalb des Nahbereichs.
      expect(visible, isNot(contains((x: 0, y: 6))));
      // Vor dem Spieler, in Blickrichtung, sollte sichtbar sein.
      expect(visible, contains((x: 0, y: -6)));
    });

    test('Tiles außerhalb des Sichtradius sind unsichtbar', () {
      final world = World(1);
      final visible = computeFieldOfView(
        world: world,
        originX: 0,
        originY: 0,
        z: ZLevel.surface,
        facingX: 0,
        facingY: 1,
        viewRadius: 3,
      );
      expect(visible, isNot(contains((x: 0, y: 10))));
    });

    test('Sichtblocker verdecken dahinterliegende Tiles, aber nicht sich selbst (FOW-03)', () {
      final world = World(1);
      // Weg explizit sichtfrei setzen, bis auf den bewusst platzierten
      // Blocker — sonst könnte zufällige Weltgenerierung die Sicht schon
      // vorher blockieren und den Test aus dem falschen Grund bestehen
      // lassen (oder fehlschlagen lassen).
      for (var y = -8; y <= 8; y++) {
        world.setTileAt(0, y, ZLevel.surface, const Tile(TileType.grass));
      }
      world.setTileAt(0, 3, ZLevel.surface, const Tile(TileType.forest));

      final visible = computeFieldOfView(
        world: world,
        originX: 0,
        originY: 0,
        z: ZLevel.surface,
        facingX: 0,
        facingY: 1,
        viewRadius: 8,
        fieldOfViewDegrees: 160,
      );

      expect(visible, contains((x: 0, y: 3))); // der Wald selbst ist sichtbar
      expect(visible, isNot(contains((x: 0, y: 5)))); // dahinter nicht mehr
    });

    test('Wasser blockiert die Sicht nicht, obwohl es Bewegung blockiert', () {
      final world = World(1);
      for (var y = -8; y <= 8; y++) {
        world.setTileAt(0, y, ZLevel.surface, const Tile(TileType.grass));
      }
      world.setTileAt(0, 3, ZLevel.surface, const Tile(TileType.water));

      final visible = computeFieldOfView(
        world: world,
        originX: 0,
        originY: 0,
        z: ZLevel.surface,
        facingX: 0,
        facingY: 1,
        viewRadius: 8,
        fieldOfViewDegrees: 160,
      );

      expect(visible, contains((x: 0, y: 5)));
    });
  });
}
