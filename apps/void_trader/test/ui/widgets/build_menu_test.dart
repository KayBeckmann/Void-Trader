import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_content/vt_content.dart';
import 'package:vt_core/vt_core.dart';
import 'package:void_trader/ui/widgets/build_menu.dart';

void main() {
  testWidgets('zeigt jeden Gebäudetyp mit Namen und Kosten', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildMenu(selected: null, inventory: const {}, onSelect: (_) {}),
        ),
      ),
    );

    for (final type in BuildingType.values) {
      expect(find.text(buildingDefinitionFor(type).name), findsOneWidget);
    }
  });

  testWidgets('markiert leistbare vs. nicht leistbare Gebäude unterschiedlich', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildMenu(
            selected: null,
            // Reicht für Mauer (3 Stein), aber nicht für Landepad.
            inventory: const {Resource.stone: 3},
            onSelect: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
    expect(find.byIcon(Icons.block), findsWidgets);
  });

  testWidgets('ein Tap meldet den zugehörigen BuildingType', (tester) async {
    BuildingType? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildMenu(
            selected: null,
            inventory: const {},
            onSelect: (type) => selected = type,
          ),
        ),
      ),
    );

    await tester.tap(find.text(buildingDefinitionFor(BuildingType.workbench).name));
    expect(selected, BuildingType.workbench);
  });
}
