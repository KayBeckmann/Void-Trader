import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_trader/ui/tool_mode.dart';
import 'package:void_trader/ui/widgets/toolbelt_panel.dart';

void main() {
  testWidgets('zeigt einen Button je ToolMode und markiert den aktiven', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolbeltPanel(activeTool: ToolMode.dig, onSelect: (_) {}),
        ),
      ),
    );

    for (final mode in ToolMode.values) {
      expect(find.text(mode.label), findsOneWidget);
    }
  });

  testWidgets('ein Tap auf einen Button meldet den zugehörigen ToolMode', (tester) async {
    ToolMode? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolbeltPanel(
            activeTool: ToolMode.inspect,
            onSelect: (mode) => selected = mode,
          ),
        ),
      ),
    );

    await tester.tap(find.text(ToolMode.craft.label));
    expect(selected, ToolMode.craft);
  });
}
