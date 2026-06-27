import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../../core/domain/star_system.dart';

typedef JumpCallback = void Function(JumpGate gate);

class JumpGateComponent extends PositionComponent {
  final JumpGate gate;
  final JumpCallback? onJump;

  static const double _activationRadius = 100.0;
  static const double _gateSize = 40.0;

  bool _playerNearby = false;
  double _rotTimer = 0;

  late final Paint _ringPaint;
  late final Paint _corePaint;
  late final Paint _activePaint;

  JumpGateComponent({required this.gate, this.onJump})
      : super(
          position: Vector2(gate.x, gate.y),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    _ringPaint = Paint()
      ..color = const Color(0xFF7C4DFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    _corePaint = Paint()
      ..color = const Color(0xFFAA00FF).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    _activePaint = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
  }

  void updatePlayerProximity(Vector2 playerPos) {
    _playerNearby = playerPos.distanceTo(position) < _activationRadius;
  }

  void tryJump() {
    if (_playerNearby) onJump?.call(gate);
  }

  @override
  void update(double dt) {
    _rotTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    // glow when nearby
    if (_playerNearby) {
      canvas.drawCircle(Offset.zero, _gateSize * 2.5, _activePaint);
    }
    // rotating outer ring
    canvas.save();
    canvas.rotate(_rotTimer * 0.8);
    canvas.drawCircle(Offset.zero, _gateSize * 1.5, _ringPaint);
    // diamond gate shape
    final path = Path()
      ..moveTo(0, -_gateSize)
      ..lineTo(_gateSize * 0.6, 0)
      ..lineTo(0, _gateSize)
      ..lineTo(-_gateSize * 0.6, 0)
      ..close();
    canvas.drawPath(path, _corePaint);
    final outlinePaint = Paint()
      ..color = const Color(0xFF7C4DFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, outlinePaint);
    canvas.restore();
    // label
    if (_playerNearby) {
      _drawLabel(canvas, gate.targetSystemId.toUpperCase());
    }
  }

  void _drawLabel(Canvas canvas, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: '→ $text',
        style: const TextStyle(
          color: Color(0xFFCE93D8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(-tp.width / 2, -_gateSize * 3),
    );
  }

}
