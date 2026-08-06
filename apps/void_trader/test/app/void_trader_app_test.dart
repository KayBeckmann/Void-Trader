import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_trader/app/void_trader_app.dart';

/// Roadmap-Sofort-Korrektur "Fullscreen-Spieldesign, Minimap und
/// Space-HUD-Polish", Teil HUD-09: das Spiel soll den gesamten verfügbaren
/// Bildschirm füllen, keine kleine Canvas-Insel mit ungenutztem Rand.
void main() {
  testWidgets('GameWidget füllt bei typischen Desktop-Breiten den ganzen Viewport', (
    tester,
  ) async {
    // Größere, "typische Desktop"-Testfläche statt der 800x600-Vorgabe —
    // deckt eher auf, wenn irgendwo eine feste Breite/Höhe statt "füllt
    // Elternbreite" hängt.
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(VoidTraderApp());
    await tester.pump();

    // find.byType(GameWidget) findet nichts: GameWidget ist generisch
    // (GameWidget<VoidTraderGame>), und byType vergleicht exakte
    // Typ-Objekte — die Konkretisierung mit Typparameter zählt dafür
    // als "anderer Typ". byWidgetPredicate mit `is GameWidget` erfasst
    // jede Konkretisierung.
    final gameWidgetFinder = find.byWidgetPredicate((widget) => widget is GameWidget);
    final gameWidgetSize = tester.getSize(gameWidgetFinder);
    expect(gameWidgetSize, const Size(1600, 900));
  });

  testWidgets('GameWidget füllt auch eine kleinere Bildschirmbreite vollständig', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(VoidTraderApp());
    await tester.pump();

    // find.byType(GameWidget) findet nichts: GameWidget ist generisch
    // (GameWidget<VoidTraderGame>), und byType vergleicht exakte
    // Typ-Objekte — die Konkretisierung mit Typparameter zählt dafür
    // als "anderer Typ". byWidgetPredicate mit `is GameWidget` erfasst
    // jede Konkretisierung.
    final gameWidgetFinder = find.byWidgetPredicate((widget) => widget is GameWidget);
    final gameWidgetSize = tester.getSize(gameWidgetFinder);
    expect(gameWidgetSize, const Size(1024, 768));
  });
}
