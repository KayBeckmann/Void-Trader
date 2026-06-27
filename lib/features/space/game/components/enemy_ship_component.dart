import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../../core/domain/ship_stats.dart';
import 'projectile_component.dart';

enum _PirateState { patrol, chase, attack, flee }

class EnemyShipComponent extends PositionComponent with CollisionCallbacks {
  static const double _detectRadius = 450.0;
  static const double _attackRadius = 280.0;
  static const double _fleeHullThreshold = 0.2;
  static const double _maxSpeed = 180.0;
  static const double _fireRate = 0.65;

  final ShipStats stats = ShipStats.pirateBasic();
  final PositionComponent player;
  final VoidCallback? onDestroyed;

  _PirateState _state = _PirateState.patrol;
  Vector2 _patrolTarget = Vector2.zero();
  final Vector2 _velocity = Vector2.zero();
  double _fireCooldown = 0;
  double _patrolTimer = 0;

  EnemyShipComponent({
    required Vector2 position,
    required this.player,
    this.onDestroyed,
  }) : super(
          position: position,
          size: Vector2(28, 28),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(_PirateShipPainter(size: size));
    add(RectangleHitbox()..isSolid = false);
    _pickPatrolTarget();
  }

  void applyDamage(double amount) {
    final destroyed = stats.applyDamage(amount);
    if (destroyed) {
      onDestroyed?.call();
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    stats.update(dt);

    final toPlayer = player.position - position;
    final dist = toPlayer.length;

    // State machine
    if (stats.hullPercent < _fleeHullThreshold) {
      _state = _PirateState.flee;
    } else if (dist < _attackRadius) {
      _state = _PirateState.attack;
    } else if (dist < _detectRadius) {
      _state = _PirateState.chase;
    } else {
      _state = _PirateState.patrol;
    }

    switch (_state) {
      case _PirateState.patrol:
        _doPatrol(dt);
      case _PirateState.chase:
        _steer(toPlayer.normalized(), dt);
      case _PirateState.attack:
        _steer(toPlayer.normalized(), dt);
        _doFire(toPlayer.normalized());
      case _PirateState.flee:
        _steer(-toPlayer.normalized(), dt);
    }

    if (_velocity.length > _maxSpeed) _velocity.scaleTo(_maxSpeed);
    position += _velocity * dt;

    if (_fireCooldown > 0) _fireCooldown -= dt;
  }

  void _steer(Vector2 dir, double dt) {
    _velocity.add(dir * (280 * dt));
    if (_velocity.length > 10) {
      angle = _velocity.angleToSigned(Vector2(0, -1));
    }
  }

  void _doPatrol(double dt) {
    _patrolTimer -= dt;
    final toTarget = _patrolTarget - position;
    if (toTarget.length < 40 || _patrolTimer <= 0) {
      _pickPatrolTarget();
    }
    _steer(toTarget.normalized(), dt);
  }

  void _doFire(Vector2 dir) {
    if (_fireCooldown > 0) return;
    _fireCooldown = _fireRate;
    // Slight spread
    final spread = (position.x % 0.3) - 0.15;
    final fireDir = Vector2(dir.x + spread, dir.y + spread);
    parent?.add(ProjectileComponent(
      position: position.clone(),
      direction: fireDir,
      damage: 12,
      owner: ProjectileOwner.enemy,
      color: const Color(0xFFFF5722),
    ));
  }

  void _pickPatrolTarget() {
    _patrolTimer = 4.0 + (position.x.abs() % 3.0);
    _patrolTarget = position + Vector2(
      (position.y % 200) - 100,
      (position.x % 200) - 100,
    );
  }
}

class _PirateShipPainter extends Component with HasPaint {
  final Vector2 size;
  _PirateShipPainter({required this.size});

  @override
  void render(Canvas canvas) {
    final bodyPaint = Paint()..color = const Color(0xFFE53935);
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x * 0.85, size.y * 0.6)
      ..lineTo(size.x / 2, size.y * 0.4)
      ..lineTo(size.x * 0.15, size.y * 0.6)
      ..close();
    canvas.drawPath(path, bodyPaint);

    final wingPaint = Paint()..color = const Color(0xFFB71C1C);
    final leftWing = Path()
      ..moveTo(0, size.y)
      ..lineTo(size.x * 0.15, size.y * 0.6)
      ..lineTo(size.x / 2, size.y * 0.4)
      ..close();
    canvas.drawPath(leftWing, wingPaint);

    final rightWing = Path()
      ..moveTo(size.x, size.y)
      ..lineTo(size.x * 0.85, size.y * 0.6)
      ..lineTo(size.x / 2, size.y * 0.4)
      ..close();
    canvas.drawPath(rightWing, wingPaint);

    final enginePaint = Paint()..color = const Color(0xFFFFAB40);
    canvas.drawCircle(Offset(size.x / 2, size.y * 0.5), 3, enginePaint);
  }
}
