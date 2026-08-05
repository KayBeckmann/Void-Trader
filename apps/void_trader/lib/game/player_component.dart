import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// Steuerbare Spielerfigur für die Debug-Karte (Phase 1: erste
/// Harvest-Moon-Schleife).
///
/// Bewegung per Tastatur (WASD/Pfeiltasten), diagonal normalisiert damit
/// sie nicht schneller ist als geradeaus. Grafik ist bewusst ein simples
/// Rechteck — echte Sprites kommen mit der Pixel-Art-Integration.
class PlayerComponent extends PositionComponent with KeyboardHandler {
  final double speed;
  Vector2 velocity = Vector2.zero();

  /// Wird einmalig beim Drücken der Grab-/Abbau-Taste (Leertaste/E) mit der
  /// aktuellen Spielerposition aufgerufen. Die eigentliche Abbau-Logik lebt
  /// bewusst außerhalb dieser Komponente (siehe VoidTraderGame.digAt), damit
  /// PlayerComponent unabhängig vom Spiel testbar bleibt.
  final bool Function(Vector2 position)? onDig;

  PlayerComponent({required Vector2 position, this.speed = 120, this.onDig})
    : super(position: position, size: Vector2.all(12), anchor: Anchor.center);

  final Paint _paint = Paint()..color = const Color(0xFFFFC107);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final up = _pressed(keysPressed, LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW);
    final down = _pressed(keysPressed, LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS);
    final left = _pressed(keysPressed, LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA);
    final right = _pressed(keysPressed, LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD);

    final direction = Vector2(
      (right ? 1 : 0) - (left ? 1 : 0),
      (down ? 1 : 0) - (up ? 1 : 0),
    );

    velocity = direction.length2 > 0 ? (direction.normalized() * speed) : Vector2.zero();

    // Nur bei KeyDownEvent auslösen, sonst würde Gedrückthalten den Abbau
    // jeden Frame erneut triggern.
    if (event is KeyDownEvent && _isDigKey(event.logicalKey)) {
      onDig?.call(position);
    }

    return true;
  }

  bool _isDigKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyE;

  bool _pressed(
    Set<LogicalKeyboardKey> keysPressed,
    LogicalKeyboardKey a,
    LogicalKeyboardKey b,
  ) {
    return keysPressed.contains(a) || keysPressed.contains(b);
  }
}
