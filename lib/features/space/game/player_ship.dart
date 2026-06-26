import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerShip extends PositionComponent with KeyboardHandler {
  static const double _maxSpeed = 300.0;
  static const double _acceleration = 600.0;
  static const double _drag = 0.92;

  final Vector2 _velocity = Vector2.zero();

  // Keyboard input state
  final Set<LogicalKeyboardKey> _heldKeys = {};

  PlayerShip()
      : super(
          size: Vector2(32, 32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2.zero();
    add(_ShipPainter(size: size));
  }

  void applyJoystick(Vector2 delta) {
    if (delta.isZero()) return;
    final thrust = delta.normalized() * _acceleration;
    _velocity.add(thrust);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _heldKeys
      ..clear()
      ..addAll(keysPressed);
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _applyKeyboardInput(dt);
    _velocity.scale(_drag);
    if (_velocity.length > _maxSpeed) {
      _velocity.scaleTo(_maxSpeed);
    }
    position.add(_velocity * dt);

    if (_velocity.length > 10) {
      angle = _velocity.angleToSigned(Vector2(0, -1));
    }
  }

  void _applyKeyboardInput(double dt) {
    final dir = Vector2.zero();
    if (_heldKeys.contains(LogicalKeyboardKey.keyW) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowUp)) { dir.y -= 1; }
    if (_heldKeys.contains(LogicalKeyboardKey.keyS) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowDown)) { dir.y += 1; }
    if (_heldKeys.contains(LogicalKeyboardKey.keyA) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowLeft)) { dir.x -= 1; }
    if (_heldKeys.contains(LogicalKeyboardKey.keyD) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowRight)) { dir.x += 1; }
    if (!dir.isZero()) {
      _velocity.add(dir.normalized() * _acceleration * dt);
    }
  }
}

// Placeholder painter — ersetzt durch Pixel-Art-Sprite sobald Asset-Pack gewählt ist
class _ShipPainter extends Component with HasPaint {
  final Vector2 size;
  _ShipPainter({required this.size});

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF00E5FF);
    // Simple triangle pointing up
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(size.x / 2, size.y * 0.75)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(path, paint);

    final enginePaint = Paint()..color = const Color(0xFFFF6D00);
    canvas.drawCircle(
      Offset(size.x / 2, size.y * 0.85),
      4,
      enginePaint,
    );
  }
}
