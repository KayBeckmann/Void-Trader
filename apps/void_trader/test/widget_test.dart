import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_trader/app/void_trader_app.dart';

void main() {
  testWidgets('VoidTraderApp startet ohne Fehler', (WidgetTester tester) async {
    await tester.pumpWidget(const VoidTraderApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
