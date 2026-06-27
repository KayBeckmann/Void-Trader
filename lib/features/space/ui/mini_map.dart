import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/domain/star_system.dart';

class MiniMap extends StatelessWidget {
  final StarSystem system;
  final Vector2 playerPosition;
  final double mapSize;

  const MiniMap({
    super.key,
    required this.system,
    required this.playerPosition,
    this.mapSize = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: mapSize,
      height: mapSize,
      decoration: BoxDecoration(
        color: const Color(0xFF050A14).withValues(alpha: 0.85),
        border: Border.all(color: const Color(0xFF1A3A5C), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CustomPaint(
          painter: _MiniMapPainter(
            system: system,
            playerPosition: playerPosition,
          ),
        ),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  final StarSystem system;
  final Vector2 playerPosition;

  static const double _worldRadius = 1600.0; // max coordinate extent

  _MiniMapPainter({required this.system, required this.playerPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = (size.width / 2 - 4) / _worldRadius;

    Offset toMap(double x, double y) =>
        Offset(cx + x * scale, cy + y * scale);

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF0D2040)
      ..strokeWidth = 0.5;
    for (var i = -2; i <= 2; i++) {
      final d = i * size.width / 4;
      canvas.drawLine(Offset(cx + d, 0), Offset(cx + d, size.height), gridPaint);
      canvas.drawLine(Offset(0, cy + d), Offset(size.width, cy + d), gridPaint);
    }

    // Sun
    final sunPaint = Paint()..color = const Color(0xFFFFF176);
    canvas.drawCircle(Offset(cx, cy), 4.5, sunPaint);

    // Asteroid fields
    final beltPaint = Paint()
      ..color = const Color(0xFF607D8B).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    for (final f in system.asteroidFields) {
      canvas.drawCircle(toMap(f.x, f.y), math.max(2, f.radius * scale), beltPaint);
    }

    // Planets
    for (final p in system.planets) {
      final color = _planetColor(p.type);
      final paint = Paint()..color = color;
      canvas.drawCircle(toMap(p.x, p.y), 3.5, paint);
      if (p.isPlayerBase) {
        final ringPaint = Paint()
          ..color = const Color(0xFF00E5FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(toMap(p.x, p.y), 6.0, ringPaint);
      }
    }

    // Jump gates
    final gatePaint = Paint()..color = const Color(0xFF7C4DFF);
    for (final g in system.jumpGates) {
      final pos = toMap(g.x, g.y);
      canvas.drawRect(
        Rect.fromCenter(center: pos, width: 5, height: 5),
        gatePaint,
      );
    }

    // Player
    final playerPos = toMap(playerPosition.x, playerPosition.y);
    final playerPaint = Paint()..color = const Color(0xFF69FF47);
    canvas.drawCircle(playerPos, 3, playerPaint);
    // Player direction marker (small triangle)
    final tp = Path()
      ..moveTo(playerPos.dx, playerPos.dy - 7)
      ..lineTo(playerPos.dx - 3, playerPos.dy + 2)
      ..lineTo(playerPos.dx + 3, playerPos.dy + 2)
      ..close();
    canvas.drawPath(tp, playerPaint);

    // Border overlay
    final borderPaint = Paint()
      ..color = const Color(0xFF1A3A5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(7),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_MiniMapPainter old) =>
      old.playerPosition != playerPosition;

  Color _planetColor(String type) => switch (type) {
        'industrial' => const Color(0xFFB0BEC5),
        'trade' => const Color(0xFFFFF176),
        'colony' => const Color(0xFF81C784),
        'habitat' => const Color(0xFF4FC3F7),
        'mining' => const Color(0xFFBCAAA4),
        _ => const Color(0xFF90A4AE),
      };
}
