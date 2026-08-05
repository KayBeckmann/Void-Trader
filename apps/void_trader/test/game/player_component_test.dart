import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_trader/game/player_component.dart';

const _dummyKeyEvent = KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.keyW,
  logicalKey: LogicalKeyboardKey.keyW,
  timeStamp: Duration.zero,
);

void main() {
  group('PlayerComponent Steuerung', () {
    test('keine Taste gedrückt -> Geschwindigkeit bleibt null', () {
      final player = PlayerComponent(position: Vector2.zero());
      player.onKeyEvent(_dummyKeyEvent, <LogicalKeyboardKey>{});
      expect(player.velocity, Vector2.zero());
    });

    test('W/Pfeil-hoch bewegt nach oben (negative y-Richtung)', () {
      final player = PlayerComponent(position: Vector2.zero());
      player.onKeyEvent(_dummyKeyEvent, {LogicalKeyboardKey.keyW});
      expect(player.velocity.y, lessThan(0));
      expect(player.velocity.x, 0);
    });

    test('diagonale Bewegung wird auf speed normalisiert', () {
      final player = PlayerComponent(position: Vector2.zero(), speed: 100);
      player.onKeyEvent(_dummyKeyEvent, {
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyD,
      });
      // Flames Vector2 rechnet intern mit einfacher Gleitkommagenauigkeit
      // (float32), daher eine großzügigere Toleranz als bei double-Mathe.
      expect(player.velocity.length, closeTo(100, 1e-3));
    });

    test('update() verschiebt die Position gemäß Geschwindigkeit * dt', () {
      final player = PlayerComponent(position: Vector2.zero());
      player.velocity = Vector2(10, 0);
      player.update(2.0);
      expect(player.position, Vector2(20, 0));
    });

    test('onKeyEvent gibt true zurück (blockiert Propagation nicht)', () {
      final player = PlayerComponent(position: Vector2.zero());
      final result = player.onKeyEvent(_dummyKeyEvent, <LogicalKeyboardKey>{});
      expect(result, isTrue);
    });
  });
}
