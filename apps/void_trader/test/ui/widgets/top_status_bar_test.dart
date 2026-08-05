import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_physics/vt_physics.dart';
import 'package:void_trader/ui/widgets/top_status_bar.dart';

void main() {
  testWidgets('zeigt Zeitlabel und Wetter mit Beispielzustand', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TopStatusBar(isDay: true, timeLabel: '08:15', weather: Weather.rain),
        ),
      ),
    );

    expect(find.text('08:15'), findsOneWidget);
    expect(find.text('Regen'), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
  });

  testWidgets('zeigt Nacht-Icon, wenn isDay false ist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TopStatusBar(isDay: false, timeLabel: '23:40', weather: Weather.clear),
        ),
      ),
    );

    expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
  });
}
