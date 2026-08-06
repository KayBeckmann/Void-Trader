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

  /// Zuletzt genutzte Bewegungsrichtung als Einheitsvektor in eine der vier
  /// Himmelsrichtungen (Roadmap FOW-02: der Sichtkegel folgt der
  /// Blickrichtung). Bleibt beim Stehenbleiben auf dem zuletzt genutzten
  /// Wert stehen, statt neutral zu werden — der Spieler "schaut" weiter
  /// dorthin, wo er zuletzt hinlief. Start: nach unten/Süden.
  Vector2 facingDirection = Vector2(0, 1);

  /// Wird einmalig beim Drücken einer Aktionstaste (jede Taste außer den
  /// Bewegungstasten) mit der gedrückten Taste und der aktuellen
  /// Spielerposition aufgerufen. Welche Taste welche Aktion auslöst (Graben,
  /// Bauen, Craften, …) entscheidet bewusst VoidTraderGame, nicht diese
  /// Komponente — PlayerComponent bleibt so unabhängig vom Spiel testbar.
  final void Function(LogicalKeyboardKey key, Vector2 position)? onAction;

  /// Prüft, ob eine Zielposition betreten werden darf (Roadmap MOV-02) —
  /// `null` bedeutet "keine Kollisionsprüfung", z.B. in reinen
  /// Steuerungstests ohne Weltbezug. Die eigentliche Regel (welches
  /// Tile/Gebäude blockiert) lebt in VoidTraderGame/vt_world, nicht hier —
  /// PlayerComponent bleibt so unabhängig von der Weltimplementierung
  /// testbar.
  final bool Function(Vector2 targetPosition)? canMoveTo;

  PlayerComponent({
    required Vector2 position,
    this.speed = 120,
    this.onAction,
    this.canMoveTo,
  }) : super(position: position, size: Vector2(28, 34), anchor: Anchor.center);

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
    if (velocity.length2 == 0) return;

    // Achsen getrennt bewegen/prüfen statt der Gesamt-Bewegung: so
    // gleitet der Spieler an einem Hindernis entlang, statt bei
    // diagonaler Bewegung komplett stehen zu bleiben, sobald nur eine
    // Achse blockiert ist (Roadmap MOV-02). Prüft nur den Mittelpunkt
    // (Anchor.center), nicht die volle Kollisionsbox — für "Kollision V1"
    // bewusst ausreichend, siehe Roadmap-Rahmung.
    final deltaX = Vector2(velocity.x * dt, 0);
    if (deltaX.x != 0) {
      final candidate = position + deltaX;
      if (canMoveTo?.call(candidate) ?? true) position = candidate;
    }
    final deltaY = Vector2(0, velocity.y * dt);
    if (deltaY.y != 0) {
      final candidate = position + deltaY;
      if (canMoveTo?.call(candidate) ?? true) position = candidate;
    }
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
    if (direction.length2 > 0) {
      facingDirection = _cardinal(direction);
    }

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

  /// Reduziert eine (ggf. diagonale) Bewegungsrichtung auf eine der vier
  /// Himmelsrichtungen — die dominante Achse gewinnt. Einfacher als echte
  /// 8-Richtungs-Sicht, aber ausreichend für "Sichtkegel V1" (Roadmap
  /// FOW-02).
  static Vector2 _cardinal(Vector2 direction) {
    if (direction.x.abs() > direction.y.abs()) {
      return Vector2(direction.x > 0 ? 1 : -1, 0);
    }
    return Vector2(0, direction.y > 0 ? 1 : -1);
  }
}
