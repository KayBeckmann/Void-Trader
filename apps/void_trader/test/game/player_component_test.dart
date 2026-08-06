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

  group('PlayerComponent Kollision (Roadmap MOV-02)', () {
    test('canMoveTo == null bewegt sich ungebremst (Rückwärtskompatibilität)', () {
      final player = PlayerComponent(position: Vector2.zero());
      player.velocity = Vector2(10, 5);
      player.update(1.0);
      expect(player.position, Vector2(10, 5));
    });

    test('canMoveTo == false blockiert die Bewegung vollständig', () {
      final player = PlayerComponent(position: Vector2.zero(), canMoveTo: (_) => false);
      player.velocity = Vector2(10, 0);
      player.update(1.0);
      expect(player.position, Vector2.zero());
    });

    test('blockierte Achse lässt die andere Achse weiter gleiten', () {
      // x-Bewegung wird blockiert, y-Bewegung bleibt erlaubt — simuliert
      // "an einer Wand entlanggleiten" bei diagonaler Bewegung.
      final player = PlayerComponent(
        position: Vector2.zero(),
        canMoveTo: (target) => target.x == 0,
      );
      player.velocity = Vector2(10, 10);
      player.update(1.0);

      expect(player.position.x, 0);
      expect(player.position.y, 10);
    });

    test('canMoveTo wird mit der vorgeschlagenen Zielposition aufgerufen', () {
      final calls = <Vector2>[];
      final player = PlayerComponent(
        position: Vector2(100, 100),
        canMoveTo: (target) {
          calls.add(target.clone());
          return true;
        },
      );
      player.velocity = Vector2(10, -5);
      player.update(1.0);

      expect(calls, [Vector2(110, 100), Vector2(110, 95)]);
    });
  });

  group('PlayerComponent.facingDirection (Roadmap FOW-02)', () {
    test('startet nach unten/Süden', () {
      final player = PlayerComponent(position: Vector2.zero());
      expect(player.facingDirection, Vector2(0, 1));
    });

    test('folgt der Bewegungstaste (dominante Achse)', () {
      final player = PlayerComponent(position: Vector2.zero());
      player.onKeyEvent(_dummyKeyEvent, {LogicalKeyboardKey.keyD});
      expect(player.facingDirection, Vector2(1, 0));
    });

    test('bleibt beim Loslassen der Taste auf der letzten Richtung stehen', () {
      final player = PlayerComponent(position: Vector2.zero());
      player.onKeyEvent(_dummyKeyEvent, {LogicalKeyboardKey.keyW});
      expect(player.facingDirection, Vector2(0, -1));

      player.onKeyEvent(_dummyKeyEvent, <LogicalKeyboardKey>{});
      expect(player.velocity, Vector2.zero());
      expect(player.facingDirection, Vector2(0, -1));
    });
  });

  group('PlayerComponent Aktionstasten', () {
    const spaceDown = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.space,
      logicalKey: LogicalKeyboardKey.space,
      timeStamp: Duration.zero,
    );
    const digit1Down = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.digit1,
      logicalKey: LogicalKeyboardKey.digit1,
      timeStamp: Duration.zero,
    );

    test('Leertaste ruft onAction mit Taste + aktueller Position auf', () {
      LogicalKeyboardKey? capturedKey;
      Vector2? capturedPosition;
      final player = PlayerComponent(
        position: Vector2(5, 7),
        onAction: (key, pos) {
          capturedKey = key;
          capturedPosition = pos;
        },
      );

      player.onKeyEvent(spaceDown, {LogicalKeyboardKey.space});

      expect(capturedKey, LogicalKeyboardKey.space);
      expect(capturedPosition, Vector2(5, 7));
    });

    test('weitere Aktionstasten (z.B. "1" fürs Bauen) lösen onAction ebenfalls aus', () {
      LogicalKeyboardKey? capturedKey;
      final player = PlayerComponent(
        position: Vector2.zero(),
        onAction: (key, pos) => capturedKey = key,
      );

      player.onKeyEvent(digit1Down, {LogicalKeyboardKey.digit1});

      expect(capturedKey, LogicalKeyboardKey.digit1);
    });

    test('reine Bewegungstasten lösen onAction nicht aus', () {
      var called = false;
      final player = PlayerComponent(
        position: Vector2.zero(),
        onAction: (key, pos) => called = true,
      );

      player.onKeyEvent(_dummyKeyEvent, {LogicalKeyboardKey.keyW});

      expect(called, isFalse);
    });
  });
}
