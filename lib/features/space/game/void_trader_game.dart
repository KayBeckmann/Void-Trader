import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/data/system_repository.dart';
import '../../../core/domain/star_system.dart';
import 'components/asteroid_field_component.dart';
import 'components/jump_gate_component.dart';
import 'components/planet_component.dart';
import 'components/sun_component.dart';
import 'player_ship.dart';

class VoidTraderGame extends FlameGame with HasKeyboardHandlerComponents {
  late PlayerShip _player;
  late JoystickComponent _joystick;

  final List<PlanetComponent> _planets = [];
  final List<JumpGateComponent> _gates = [];

  Planet? pendingDock;
  JumpGate? pendingJump;

  VoidCallback? onDockRequested;
  VoidCallback? onJumpRequested;

  @override
  Color backgroundColor() => const Color(0xFF050A14);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await _loadSystem('helion');

    _player = PlayerShip();
    await add(_player);

    camera.viewfinder.visibleGameSize = Vector2(800, 600);
    camera.follow(_player, maxSpeed: 600);

    await _addJoystick();
  }

  Future<void> _loadSystem(String id) async {
    final system = await SystemRepository.findById(id) ??
        (await SystemRepository.loadAll()).first;
    _planets.clear();
    _gates.clear();

    await add(_StarfieldComponent());
    await add(SunComponent(position: Vector2.zero()));

    for (final planet in system.planets) {
      final comp = PlanetComponent(
        planet: planet,
        onDockRequest: (p) {
          pendingDock = p;
          onDockRequested?.call();
        },
      );
      _planets.add(comp);
      await add(comp);
    }

    for (final field in system.asteroidFields) {
      await add(AsteroidFieldComponent(field: field));
    }

    for (final gate in system.jumpGates) {
      final comp = JumpGateComponent(
        gate: gate,
        onJump: (g) {
          pendingJump = g;
          onJumpRequested?.call();
        },
      );
      _gates.add(comp);
      await add(comp);
    }
  }

  Future<void> _addJoystick() async {
    final knob = CircleComponent(
      radius: 20,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    final background = CircleComponent(
      radius: 60,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
    _joystick = JoystickComponent(
      knob: knob,
      background: background,
      margin: const EdgeInsets.only(left: 48, bottom: 48),
    );
    await camera.viewport.add(_joystick);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _player.applyJoystick(_joystick.relativeDelta);

    final playerPos = _player.position;
    for (final p in _planets) {
      p.updatePlayerProximity(playerPos);
    }
    for (final g in _gates) {
      g.updatePlayerProximity(playerPos);
    }
  }

  // F key triggers nearest interaction
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyF) {
      _triggerNearestInteraction();
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  void _triggerNearestInteraction() {
    for (final g in _gates) {
      g.tryJump();
    }
    for (final p in _planets) {
      p.tryDock();
    }
  }
}

class _StarfieldComponent extends Component {
  static const int _count = 200;
  final _stars = <_Star>[];

  @override
  Future<void> onLoad() async {
    var seed = 0xDEADBEEF;
    double nextRand() {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      return seed / 0xFFFFFFFF;
    }
    for (var i = 0; i < _count; i++) {
      final x = nextRand() * 4000 - 2000;
      final y = nextRand() * 4000 - 2000;
      final brightness = 0.3 + nextRand() * 0.7;
      _stars.add(_Star(x: x, y: y, brightness: brightness));
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      paint.color = Color.fromRGBO(255, 255, 255, s.brightness * 0.6);
      canvas.drawCircle(Offset(s.x, s.y), s.brightness * 1.5, paint);
    }
  }
}

class _Star {
  final double x, y, brightness;
  const _Star({required this.x, required this.y, required this.brightness});
}
