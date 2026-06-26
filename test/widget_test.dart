import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_trader/features/space/game/void_trader_game.dart';

void main() {
  testWidgets('VoidTraderGame erzeugt ohne Fehler', (tester) async {
    // Smoke-Test: Game-Instanz erstellen ohne Exception
    expect(() => VoidTraderGame(), returnsNormally);
  });

  testWidgets('ProviderScope rendert ohne Fehler', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
