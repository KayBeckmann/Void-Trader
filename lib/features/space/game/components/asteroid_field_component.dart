import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../../core/domain/star_system.dart';

class AsteroidFieldComponent extends PositionComponent {
  final AsteroidField field;

  static const int _count = 60;
  final List<_Rock> _rocks = [];
  final _random = math.Random();

  AsteroidFieldComponent({required this.field})
      : super(position: Vector2(field.x, field.y), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < _count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final dist = _random.nextDouble() * field.radius;
      _rocks.add(_Rock(
        offset: Offset(dist * math.cos(angle), dist * math.sin(angle)),
        size: 3 + _random.nextDouble() * 8,
        brightness: 0.35 + _random.nextDouble() * 0.45,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    final basePaint = Paint()..style = PaintingStyle.fill;
    for (final rock in _rocks) {
      basePaint.color = Color.fromRGBO(
        (160 * rock.brightness).round(),
        (155 * rock.brightness).round(),
        (150 * rock.brightness).round(),
        0.85,
      );
      canvas.drawCircle(rock.offset, rock.size, basePaint);
    }
    // field boundary (subtle)
    final boundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, field.radius, boundPaint);
  }
}

class _Rock {
  final Offset offset;
  final double size;
  final double brightness;
  const _Rock({required this.offset, required this.size, required this.brightness});
}
