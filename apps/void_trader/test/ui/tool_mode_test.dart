import 'package:flutter_test/flutter_test.dart';
import 'package:void_trader/ui/tool_mode.dart';

void main() {
  group('ToolModeLabels', () {
    test('jeder Modus hat ein nicht-leeres Label', () {
      for (final mode in ToolMode.values) {
        expect(mode.label, isNotEmpty);
      }
    });

    test('nur inspect hat keinen Tastenhinweis', () {
      expect(ToolMode.inspect.keyHint, isEmpty);
      for (final mode in ToolMode.values.where((m) => m != ToolMode.inspect)) {
        expect(mode.keyHint, isNotEmpty, reason: '$mode sollte einen Tastenhinweis haben');
      }
    });
  });
}
