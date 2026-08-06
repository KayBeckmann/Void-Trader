import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_world/vt_world.dart' as vt_world;
import 'package:void_trader/ui/minimap_data.dart';
import 'package:void_trader/ui/widgets/minimap_panel.dart';

void main() {
  testWidgets('rendert ein quadratisches Raster mit Beispieldaten ohne Fehler', (tester) async {
    final grid = List.generate(
      5,
      (_) => List.generate(
        5,
        (_) => const MinimapCell(
          terrain: MinimapTerrain.land,
          visibility: vt_world.VisibilityState.visible,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MinimapPanel(grid: grid, facingX: 0, facingY: 1),
        ),
      ),
    );

    expect(find.byType(MinimapPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rendert auch ein Raster aus ausschließlich unentdeckten Zellen', (tester) async {
    final grid = List.generate(
      3,
      (_) => List.generate(
        3,
        (_) => const MinimapCell(
          terrain: MinimapTerrain.unknown,
          visibility: vt_world.VisibilityState.unseen,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MinimapPanel(grid: grid, facingX: 0, facingY: 1),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('kommt auch ohne Blickrichtung (Nullvektor) ohne Fehler aus', (tester) async {
    final grid = [
      [
        const MinimapCell(
          terrain: MinimapTerrain.water,
          visibility: vt_world.VisibilityState.seenButNotVisible,
        ),
      ],
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MinimapPanel(grid: grid, facingX: 0, facingY: 0),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('leeres Raster wirft nicht', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MinimapPanel(grid: const [], facingX: 0, facingY: 1),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
