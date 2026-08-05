import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_trader/ui/objective.dart';
import 'package:void_trader/ui/widgets/objective_panel.dart';

void main() {
  testWidgets('zeigt jedes Ziel und markiert erfüllte sichtbar', (tester) async {
    const objectives = [
      ObjectiveStatus(description: 'Sammle 3 Stein', isComplete: true),
      ObjectiveStatus(description: 'Baue eine Werkbank', isComplete: false),
    ];

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ObjectivePanel(objectives: objectives))),
    );

    expect(find.text('Sammle 3 Stein'), findsOneWidget);
    expect(find.text('Baue eine Werkbank'), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });
}
