import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vt_system/vt_system.dart';
import 'package:void_trader/ui/widgets/system_map_panel.dart';

void main() {
  testWidgets('rendert das Standardsystem ohne Fehler', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SystemMapPanel(
          system: defaultHomeSystem,
          currentBodyId: defaultHomeSystem.homePlanet.id,
          onSelectBody: (_) {},
          onSellCargo: () {},
          onClose: () {},
        ),
      ),
    );

    expect(find.byType(SystemMapPanel), findsOneWidget);
    expect(find.textContaining(defaultHomeSystem.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ein Tap auf den Schließen-Button ruft onClose auf', (tester) async {
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SystemMapPanel(
          system: defaultHomeSystem,
          currentBodyId: defaultHomeSystem.homePlanet.id,
          onSelectBody: (_) {},
          onSellCargo: () {},
          onClose: () => closed = true,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.close));

    expect(closed, isTrue);
  });

  testWidgets('ein Tap auf einen anderen Körper ruft onSelectBody mit dessen id auf', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: SystemMapPanel(
          system: defaultHomeSystem,
          currentBodyId: defaultHomeSystem.homePlanet.id,
          onSelectBody: (id) => selected = id,
          onSellCargo: () {},
          onClose: () {},
        ),
      ),
    );

    // Trefferfläche des Heimatplaneten (Position 0,0) liegt per Layout
    // exakt in der Mitte der Kartenfläche (siehe layoutSystemBodies) —
    // bewusst die Mitte des Karten-CustomPaint anvisiert (eindeutig über
    // systemMapCanvasKey gefunden, da MaterialApp selbst weitere
    // CustomPaint-Widgets einbringt), nicht die Mitte des gesamten
    // Overlays (die liegt wegen der Titelzeile darüber verschoben).
    await tester.tapAt(tester.getCenter(find.byKey(systemMapCanvasKey)));

    expect(selected, defaultHomeSystem.homePlanet.id);
  });

  group('"Fracht verkaufen"-Button (Roadmap Phase 9 V3)', () {
    testWidgets('erscheint nicht am Heimatplaneten', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SystemMapPanel(
            system: defaultHomeSystem,
            currentBodyId: defaultHomeSystem.homePlanet.id,
            onSelectBody: (_) {},
            onSellCargo: () {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('Fracht verkaufen'), findsNothing);
    });

    testWidgets('erscheint an einer Handelsstation und ruft onSellCargo auf', (tester) async {
      final station = defaultHomeSystem.bodies.firstWhere(
        (body) => body.type == CelestialBodyType.station,
      );
      var sold = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SystemMapPanel(
            system: defaultHomeSystem,
            currentBodyId: station.id,
            onSelectBody: (_) {},
            onSellCargo: () => sold = true,
            onClose: () {},
          ),
        ),
      );

      expect(find.text('Fracht verkaufen'), findsOneWidget);
      await tester.tap(find.text('Fracht verkaufen'));

      expect(sold, isTrue);
    });
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

    await tester.pumpWidget(
      MaterialApp(
        home: SystemMapPanel(
          system: system,
          currentBodyId: 'home',
          onSelectBody: (_) {},
          onSellCargo: () {},
          onClose: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('ein System ohne Körper wirft nicht', (tester) async {
    const system = StarSystem(name: 'Leer', bodies: []);

    await tester.pumpWidget(
      MaterialApp(
        home: SystemMapPanel(
          system: system,
          currentBodyId: 'unbekannt',
          onSelectBody: (_) {},
          onSellCargo: () {},
          onClose: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
