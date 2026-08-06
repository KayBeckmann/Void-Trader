import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_core/vt_core.dart';
import 'package:void_trader/game/void_trader_game.dart';
import 'package:void_trader/ui/widgets/resource_bar.dart';

void main() {
  testWidgets('zeigt jede angezeigte Ressource als Chip mit Beispielbestand', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResourceBar(
            inventory: {Resource.stone: 7, Resource.ore: 2, Resource.component: 3},
          ),
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text(VoidTraderGame.resourceLabel(Resource.stone)), findsOneWidget);
    expect(find.text(VoidTraderGame.resourceLabel(Resource.ore)), findsOneWidget);
    expect(find.text(VoidTraderGame.resourceLabel(Resource.component)), findsOneWidget);
  });

  testWidgets('nicht im Bestand enthaltene Ressourcen fallen auf 0 zurück', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ResourceBar(inventory: {}))),
    );

    expect(find.text('0'), findsNWidgets(3));
  });

  testWidgets('zeigt Credits nicht an — die stehen in TopStatusBar (Roadmap HUD-11/12)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ResourceBar(inventory: {Resource.credits: 999})),
      ),
    );

    expect(find.text(VoidTraderGame.resourceLabel(Resource.credits)), findsNothing);
    expect(find.text('999'), findsNothing);
  });
}
