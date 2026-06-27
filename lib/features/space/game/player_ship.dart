import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/domain/ship_stats.dart';
import 'components/projectile_component.dart';

class PlayerShip extends PositionComponent with KeyboardHandler, CollisionCallbacks {
  static const double _maxSpeed = 300.0;
  static const double _acceleration = 600.0;
  static const double _drag = 0.92;
  static const double _fireRate = 0.18; // seconds between shots

  final Vector2 _velocity = Vector2.zero();
  final Set<LogicalKeyboardKey> _heldKeys = {};
  final ShipStats stats = ShipStats.playerDefault();

  double _fireCooldown = 0;
  bool _isFiring = false;

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
    add(RectangleHitbox()..isSolid = false);
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
    _isFiring = keysPressed.contains(LogicalKeyboardKey.space);
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    stats.update(dt);
    _applyKeyboardInput(dt);
    _velocity.scale(_drag);
    if (_velocity.length > _maxSpeed) {
      _velocity.scaleTo(_maxSpeed);
    }
    position.add(_velocity * dt);

    if (_velocity.length > 10) {
      angle = _velocity.angleToSigned(Vector2(0, -1));
    }

    if (_fireCooldown > 0) {
      _fireCooldown -= dt;
    }
    if (_isFiring && _fireCooldown <= 0) {
      _fire();
    }
  }

  void _fire() {
    _fireCooldown = _fireRate;
    // Shoot in the direction the ship is facing
    final dir = Vector2(0, -1)..rotate(angle);
    final proj = ProjectileComponent(
      position: position.clone(),
      direction: dir,
      damage: 18,
      owner: ProjectileOwner.player,
    );
    parent?.add(proj);
  }

  void _applyKeyboardInput(double dt) {
    final dir = Vector2.zero();
    if (_heldKeys.contains(LogicalKeyboardKey.keyW) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dir.y -= 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.keyS) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dir.y += 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.keyA) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dir.x -= 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.keyD) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dir.x += 1;
    }
    if (!dir.isZero()) {
      _velocity.add(dir.normalized() * _acceleration * dt);
    }
  }
}

class _ShipPainter extends Component with HasPaint {
  final Vector2 size;
  _ShipPainter({required this.size});

  @override
  void render(Canvas canvas) {
    final bodyPaint = Paint()..color = const Color(0xFF00E5FF);
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(size.x / 2, size.y * 0.75)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(path, bodyPaint);

    final enginePaint = Paint()..color = const Color(0xFFFF6D00);
    canvas.drawCircle(Offset(size.x / 2, size.y * 0.85), 4, enginePaint);
  }
}
