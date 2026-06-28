import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/data/system_repository.dart';
import '../../../core/domain/ship_stats.dart';
import '../../../core/domain/star_system.dart';
import 'effects/explosion_particles.dart';
import 'components/asteroid_field_component.dart';
import 'components/enemy_ship_component.dart';
import 'components/jump_gate_component.dart';
import 'components/planet_component.dart';
import 'components/projectile_component.dart';
import 'components/sun_component.dart';
import 'player_ship.dart';

class VoidTraderGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late PlayerShip _player;
  late JoystickComponent _joystick;

  final List<PlanetComponent> _planets = [];
  final List<JumpGateComponent> _gates = [];

  Planet? pendingDock;
  JumpGate? pendingJump;

  VoidCallback? onDockRequested;
  VoidCallback? onJumpRequested;
  VoidCallback? onHudUpdate;
  void Function(StarSystem)? onSystemLoaded;

  StarSystem? currentSystem;
  final playerPosition = ValueNotifier<Vector2>(Vector2.zero());
  double _hudTimer = 0;

  ShipStats get playerStats => _player.stats;

  @override
  Color backgroundColor() => const Color(0xFF050A14);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _player = PlayerShip();
    await add(_player);

    await _loadSystem('helion');

    camera.viewfinder.visibleGameSize = Vector2(800, 600);
    camera.follow(_player, maxSpeed: 600);

    await _addJoystick();
  }

  Future<void> _loadSystem(String id) async {
    final system = await SystemRepository.findById(id) ??
        (await SystemRepository.loadAll()).first;
    currentSystem = system;
    onSystemLoaded?.call(system);
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

    // Spawn a few pirate enemies in Skarrath-tier or always for testing
    await _spawnPirates(3);
  }

  Future<void> _spawnPirates(int count) async {
    final rng = math.Random();
    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist = 500.0 + rng.nextDouble() * 600.0;
      final pos = Vector2(dist * math.cos(angle), dist * math.sin(angle));
      await add(EnemyShipComponent(
        position: pos,
        player: _player,
        onDestroyed: () {/* TODO M2: drop loot */},
      ));
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
    playerPosition.value = playerPos.clone();
    for (final p in _planets) {
      p.updatePlayerProximity(playerPos);
    }
    for (final g in _gates) {
      g.updatePlayerProximity(playerPos);
    }

    _hudTimer += dt;
    if (_hudTimer > 0.1) {
      _hudTimer = 0;
      onHudUpdate?.call();
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

  // Called by ProjectileComponent when it hits something
  void handleProjectileHit({
    required PositionComponent target,
    required double damage,
    required ProjectileOwner owner,
    required Vector2 hitPos,
  }) {
    add(ExplosionParticles(
      position: hitPos,
      color: owner == ProjectileOwner.player
          ? const Color(0xFFFF6D00)
          : const Color(0xFF69FF47),
      count: 10,
    ));

    if (owner == ProjectileOwner.player && target is EnemyShipComponent) {
      target.applyDamage(damage);
    } else if (owner == ProjectileOwner.enemy && target is PlayerShip) {
      target.stats.applyDamage(damage);
      // Screen shake via camera
      camera.viewfinder.position += Vector2(
        (math.Random().nextDouble() - 0.5) * 8,
        (math.Random().nextDouble() - 0.5) * 8,
      );
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
