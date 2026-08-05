import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_core/vt_core.dart';
import 'package:void_trader/game/void_trader_game.dart';
import 'package:void_trader/ui/widgets/resource_bar.dart';

void main() {
  testWidgets('zeigt jede Ressource mit Beispielbestand', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ResourceBar(inventory: {Resource.stone: 7, Resource.ore: 2})),
      ),
    );

    expect(find.text('${VoidTraderGame.resourceLabel(Resource.stone)}: 7'), findsOneWidget);
    expect(find.text('${VoidTraderGame.resourceLabel(Resource.ore)}: 2'), findsOneWidget);
    // Nicht im Beispielbestand enthaltene Ressourcen fallen auf 0 zurück.
    expect(find.text('${VoidTraderGame.resourceLabel(Resource.credits)}: 0'), findsOneWidget);
  });
}
