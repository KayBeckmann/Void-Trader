import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_trader/ui/widgets/feedback_toast.dart';

void main() {
  testWidgets('zeigt die Meldung an, wenn eine vorhanden ist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FeedbackToast(message: 'Werkbank gebaut.'))),
    );

    expect(find.text('Werkbank gebaut.'), findsOneWidget);
  });

  testWidgets('rendert nichts sichtbares ohne Meldung', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FeedbackToast(message: null))),
    );

    expect(find.byType(SizedBox), findsWidgets);
    expect(find.text(''), findsNothing);
  });
}
