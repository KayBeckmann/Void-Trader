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

  group('PlayerComponent Graben/Abbauen', () {
    const spaceDown = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.space,
      logicalKey: LogicalKeyboardKey.space,
      timeStamp: Duration.zero,
    );
    const eDown = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyE,
      logicalKey: LogicalKeyboardKey.keyE,
      timeStamp: Duration.zero,
    );

    test('Leertaste ruft onDig mit der aktuellen Position auf', () {
      Vector2? capturedPosition;
      final player = PlayerComponent(
        position: Vector2(5, 7),
        onDig: (pos) {
          capturedPosition = pos;
          return true;
        },
      );

      player.onKeyEvent(spaceDown, {LogicalKeyboardKey.space});

      expect(capturedPosition, Vector2(5, 7));
    });

    test('E-Taste ruft onDig ebenfalls auf', () {
      var called = false;
      final player = PlayerComponent(
        position: Vector2.zero(),
        onDig: (pos) {
          called = true;
          return true;
        },
      );

      player.onKeyEvent(eDown, {LogicalKeyboardKey.keyE});

      expect(called, isTrue);
    });

    test('reine Bewegungstasten lösen onDig nicht aus', () {
      var called = false;
      final player = PlayerComponent(
        position: Vector2.zero(),
        onDig: (pos) {
          called = true;
          return true;
        },
      );

      player.onKeyEvent(_dummyKeyEvent, {LogicalKeyboardKey.keyW});

      expect(called, isFalse);
    });
  });
}
