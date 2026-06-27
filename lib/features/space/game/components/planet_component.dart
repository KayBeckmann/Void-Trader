import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../../core/domain/star_system.dart';

typedef DockingCallback = void Function(Planet planet);

class PlanetComponent extends PositionComponent {
  final Planet planet;
  final DockingCallback? onDockRequest;

  static const double _dockRadius = 140.0;
  bool _playerNearby = false;

  late final Color _planetColor;
  late final Color _rimColor;
  late final Paint _fillPaint;
  late final Paint _rimPaint;
  late final Paint _glowPaint;

  PlanetComponent({required this.planet, this.onDockRequest})
      : super(
          position: Vector2(planet.x, planet.y),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    _planetColor = _colorForType(planet.type);
    _rimColor = planet.isPlayerBase
        ? const Color(0xFF00E5FF)
        : _planetColor.withValues(alpha: 0.5);

    _fillPaint = Paint()
      ..color = _planetColor
      ..style = PaintingStyle.fill;
    _rimPaint = Paint()
      ..color = _rimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = planet.isPlayerBase ? 3.0 : 1.5;
    _glowPaint = Paint()
      ..color = _planetColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
  }

  void updatePlayerProximity(Vector2 playerPos) {
    _playerNearby = playerPos.distanceTo(position) < _dockRadius;
  }

  void tryDock() {
    if (_playerNearby) onDockRequest?.call(planet);
  }

  @override
  void render(Canvas canvas) {
    final r = planet.radius;
    // atmosphere halo
    canvas.drawCircle(Offset.zero, r * 1.35, _glowPaint);
    // planet body
    canvas.drawCircle(Offset.zero, r, _fillPaint);
    // highlight
    final hlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-r * 0.3, -r * 0.3), r * 0.42, hlPaint);
    // rim / orbit ring
    canvas.drawCircle(Offset.zero, r + 8, _rimPaint);
    // player-base marker
    if (planet.isPlayerBase) {
      final markerPaint = Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset.zero, r + 18, markerPaint);
    }
    // docking indicator
    if (_playerNearby) {
      final dockPaint = Paint()
        ..color = const Color(0xFF69FF47).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset.zero, r + 28, dockPaint);
    }
  }

  static Color _colorForType(String type) => switch (type) {
        'industrial' => const Color(0xFFB0BEC5),
        'trade' => const Color(0xFFFFF176),
        'colony' => const Color(0xFF81C784),
        'habitat' => const Color(0xFF4FC3F7),
        'mining' => const Color(0xFFBCAAA4),
        _ => const Color(0xFF90A4AE),
      };
}
