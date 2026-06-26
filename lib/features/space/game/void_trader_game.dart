import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'player_ship.dart';

class VoidTraderGame extends FlameGame with HasKeyboardHandlerComponents {
  late PlayerShip _player;
  late JoystickComponent _joystick;

  @override
  Color backgroundColor() => const Color(0xFF050A14);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _player = PlayerShip();
    await add(_player);

    camera.viewfinder.visibleGameSize = Vector2(800, 600);

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

    _setupCamera();
  }

  void _setupCamera() {
    camera.follow(_player, maxSpeed: 600);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _player.applyJoystick(_joystick.relativeDelta);
  }
}
