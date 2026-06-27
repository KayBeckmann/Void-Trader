import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ExplosionParticles extends Component {
  final Vector2 position;
  final Color color;
  final int count;

  final List<_Particle> _particles = [];
  bool _done = false;

  ExplosionParticles({
    required this.position,
    this.color = const Color(0xFFFF6D00),
    this.count = 16,
  });

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final speed = 80 + rng.nextDouble() * 180;
      _particles.add(_Particle(
        pos: position.clone(),
        vel: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
        life: 0.4 + rng.nextDouble() * 0.5,
        maxLife: 0.4 + rng.nextDouble() * 0.5,
        size: 2 + rng.nextDouble() * 4,
        color: color,
      ));
    }
  }

  @override
  void update(double dt) {
    bool allDead = true;
    for (final p in _particles) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel.scale(0.88); // drag
      if (p.life > 0) allDead = false;
    }
    if (allDead && !_done) {
      _done = true;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _particles) {
      if (p.life <= 0) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(p.pos.x, p.pos.y), p.size * alpha, paint);
    }
  }
}

class _Particle {
  Vector2 pos;
  Vector2 vel;
  double life;
  double maxLife;
  double size;
  Color color;

  _Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
  });
}
