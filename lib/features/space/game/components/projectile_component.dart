import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum ProjectileOwner { player, enemy }

class ProjectileComponent extends PositionComponent with CollisionCallbacks {
  final Vector2 velocity;
  final double damage;
  final ProjectileOwner owner;
  final Color color;

  static const double _speed = 600.0;
  static const double _lifetime = 2.5; // seconds before auto-remove

  double _age = 0;
  bool _hit = false;

  ProjectileComponent({
    required Vector2 position,
    required Vector2 direction,
    required this.damage,
    required this.owner,
    this.color = const Color(0xFF69FF47),
  })  : velocity = direction.normalized() * _speed,
        super(
          position: position,
          size: Vector2(6, 3),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    angle = velocity.angleTo(Vector2(1, 0));
    add(RectangleHitbox()..isSolid = true);
  }

  @override
  void update(double dt) {
    if (_hit) return;
    _age += dt;
    if (_age > _lifetime) {
      removeFromParent();
      return;
    }
    position += velocity * dt;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(1.5),
      ),
      paint,
    );
    // glow
    final glow = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-1, -1, size.x + 2, size.y + 2),
        const Radius.circular(2),
      ),
      glow,
    );
  }

  void markHit() {
    _hit = true;
    removeFromParent();
  }
}
