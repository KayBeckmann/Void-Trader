import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SunComponent extends PositionComponent {
  final double radius;
  final Color coreColor;
  final Color glowColor;

  late final Paint _corePaint;
  late final Paint _glowPaint;
  double _pulseTimer = 0;

  SunComponent({
    required Vector2 position,
    this.radius = 90,
    this.coreColor = const Color(0xFFFFF176),
    this.glowColor = const Color(0xFFFF8F00),
  }) : super(
          position: position,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    _corePaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill;
    _glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
  }

  @override
  void update(double dt) {
    _pulseTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 1.0 + 0.04 * math.sin(_pulseTimer * 1.8);
    // outer glow
    canvas.drawCircle(Offset.zero, radius * 2.2 * pulse, _glowPaint);
    // mid glow
    final midPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 1.5 * pulse, midPaint);
    // core
    canvas.drawCircle(Offset.zero, radius, _corePaint);
    // bright center highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(-18, -18), radius * 0.35, highlightPaint);
  }
}
