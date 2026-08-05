import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// Sprite-Datei der Spielerfigur, relativ zu `Flame.images.prefix`
/// (`assets/pixel-art/`, siehe VoidTraderGame.onLoad).
const String _spriteAssetFile = 'characters/colonist.png';

/// Steuerbare Spielerfigur für die Debug-Karte (Phase 1: erste
/// Harvest-Moon-Schleife).
///
/// Bewegung per Tastatur (WASD/Pfeiltasten), diagonal normalisiert damit
/// sie nicht schneller ist als geradeaus. Rendert einen Colonist-Sprite
/// (Sofort-Korrektur nach Webpreview 2026-08-05) statt des früheren
/// gelben Debug-Punkts; solange das Sprite noch lädt, wird ein einfaches
/// Rechteck als Platzhalter gezeichnet, damit die Figur nie unsichtbar ist.
class PlayerComponent extends PositionComponent with KeyboardHandler {
  final double speed;
  Vector2 velocity = Vector2.zero();

  /// Wird einmalig beim Drücken einer Aktionstaste (jede Taste außer den
  /// Bewegungstasten) mit der gedrückten Taste und der aktuellen
  /// Spielerposition aufgerufen. Welche Taste welche Aktion auslöst (Graben,
  /// Bauen, Craften, …) entscheidet bewusst VoidTraderGame, nicht diese
  /// Komponente — PlayerComponent bleibt so unabhängig vom Spiel testbar.
  final void Function(LogicalKeyboardKey key, Vector2 position)? onAction;

  PlayerComponent({required Vector2 position, this.speed = 120, this.onAction})
    : super(position: position, size: Vector2(28, 34), anchor: Anchor.center);

  Sprite? _sprite;
  final Paint _fallbackPaint = Paint()..color = const Color(0xFFFFC107);

  // Kein `const Set`: LogicalKeyboardKey überschreibt ==/hashCode, was in
  // konstanten Set-Literalen vom Analyzer abgelehnt wird.
  static final Set<LogicalKeyboardKey> _movementKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyD,
  };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await Sprite.load(_spriteAssetFile);
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite != null) {
      sprite.render(canvas, size: size);
    } else {
      canvas.drawRect(size.toRect(), _fallbackPaint);
    }
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

    // Nur bei KeyDownEvent auslösen, sonst würde Gedrückthalten die Aktion
    // jeden Frame erneut triggern. Bewegungstasten lösen keine Aktion aus.
    if (event is KeyDownEvent && !_movementKeys.contains(event.logicalKey)) {
      onAction?.call(event.logicalKey, position);
    }

    return true;
  }

  bool _pressed(
    Set<LogicalKeyboardKey> keysPressed,
    LogicalKeyboardKey a,
    LogicalKeyboardKey b,
  ) {
    return keysPressed.contains(a) || keysPressed.contains(b);
  }
}
