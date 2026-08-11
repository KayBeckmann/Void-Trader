import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_system/vt_system.dart';
import 'package:void_trader/ui/widgets/system_map_panel.dart';

void main() {
  testWidgets('rendert das Standardsystem ohne Fehler', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SystemMapPanel(system: defaultHomeSystem, onClose: () {}),
      ),
    );

    expect(find.byType(SystemMapPanel), findsOneWidget);
    expect(find.textContaining(defaultHomeSystem.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ein Tap ruft onClose auf', (tester) async {
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SystemMapPanel(system: defaultHomeSystem, onClose: () => closed = true),
      ),
    );
    await tester.tap(find.byType(SystemMapPanel));

    expect(closed, isTrue);
  });

  testWidgets('ein System mit nur einem Körper (Systemursprung) wirft nicht', (tester) async {
    const system = StarSystem(
      name: 'Einsam',
      bodies: [
        CelestialBody(
          id: 'home',
          name: 'Nur-Planet',
          type: CelestialBodyType.homePlanet,
          x: 0,
          y: 0,
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: SystemMapPanel(system: system, onClose: () {})));

    expect(tester.takeException(), isNull);
  });

  testWidgets('ein System ohne Körper wirft nicht', (tester) async {
    const system = StarSystem(name: 'Leer', bodies: []);

    await tester.pumpWidget(MaterialApp(home: SystemMapPanel(system: system, onClose: () {})));

    expect(tester.takeException(), isNull);
  });
}
