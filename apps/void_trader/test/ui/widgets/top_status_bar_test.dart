import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_physics/vt_physics.dart';
import 'package:void_trader/ui/widgets/top_status_bar.dart';

void main() {
  testWidgets('zeigt Zeitlabel und Wetter mit Beispielzustand', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TopStatusBar(
            isDay: true,
            timeLabel: '08:15',
            weather: Weather.rain,
            zLevelLabel: 'Oberfläche',
            credits: 42,
            shipCargoCount: 7,
          ),
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
          body: TopStatusBar(
            isDay: false,
            timeLabel: '23:40',
            weather: Weather.clear,
            zLevelLabel: 'Oberfläche',
            credits: 0,
            shipCargoCount: 0,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
  });

  testWidgets('zeigt z-Ebene, Credits und Fracht als eigene Segmente (Roadmap HUD-11)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TopStatusBar(
            isDay: true,
            timeLabel: '12:00',
            weather: Weather.clear,
            zLevelLabel: 'Hügel',
            credits: 250,
            shipCargoCount: 12,
          ),
        ),
      ),
    );

    expect(find.text('Hügel'), findsOneWidget);
    expect(find.text('250 Cr'), findsOneWidget);
    expect(find.text('12 Fracht'), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.byIcon(Icons.paid_outlined), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
  });
}
