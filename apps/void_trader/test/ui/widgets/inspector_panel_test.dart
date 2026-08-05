import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_trader/ui/tile_inspector_info.dart';
import 'package:void_trader/ui/widgets/inspector_panel.dart';

void main() {
  testWidgets('zeigt Titel, Details und verfügbare Aktion', (tester) async {
    const info = TileInspectorInfo(
      title: 'Werkbank',
      details: ['Begehbar'],
      actions: [
        InspectorActionInfo(label: 'Craften', keyHint: 'C', available: true),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InspectorPanel(info: info))),
    );

    expect(find.text('Werkbank'), findsOneWidget);
    expect(find.text('Begehbar'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('zeigt Sperrgrund bei nicht verfügbarer Aktion', (tester) async {
    const info = TileInspectorInfo(
      title: 'Werkbank',
      details: [],
      actions: [
        InspectorActionInfo(
          label: 'Craften',
          keyHint: 'C',
          available: false,
          blockedReason: 'Nicht genug Rohstoffe',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InspectorPanel(info: info))),
    );

    expect(find.byIcon(Icons.block), findsOneWidget);
    expect(find.textContaining('Nicht genug Rohstoffe'), findsOneWidget);
  });
}
