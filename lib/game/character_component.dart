import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../models/habit_type.dart';

class CharacterComponent extends PositionComponent {
  final HabitRecord record;
  late TextComponent _face;
  late CircleComponent _body;
  late double _baseY;
  final Random _random = Random();

  CharacterComponent({required this.record, required Vector2 position})
      : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _baseY = position.y;

    final size = _sizeForStage();
    final colors = _colorsForKind();

    add(
      CircleComponent(
        radius: size * 1.2,
        paint: Paint()..color = colors.withOpacity(0.12),
        anchor: Anchor.center,
      ),
    );

    _body = CircleComponent(
      radius: size,
      paint: Paint()..color = colors,
      anchor: Anchor.center,
    );
    add(_body);

    _face = TextComponent(
      text: _faceForKind(),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: size * 0.9,
          color: Colors.white,
          shadows: const [
            Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(1, 1)),
          ],
        ),
      ),
      anchor: Anchor.center,
    );
    add(_face);

    _addIdleAnimation();
    _addFlameParticles(colors);
    _addGlow(colors);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final t = DateTime.now().millisecondsSinceEpoch / 1000;
    final bounce = sin(t * 2) * 4;
    position.y = _baseY + bounce;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = size / 2;
    _baseY = position.y;
  }

  double _sizeForStage() {
    return 40 + record.currentStageIndex * 14;
  }

  Color _colorsForKind() {
    switch (record.characterKind) {
      case CharacterKind.flameFox:
        return Colors.deepOrangeAccent;
      case CharacterKind.emberDragon:
        return Colors.redAccent.shade200;
      case CharacterKind.spiritBud:
        return Colors.greenAccent.shade400;
      case CharacterKind.cyberOwl:
        return Colors.blueAccent.shade200;
      case CharacterKind.aquaSlime:
        return Colors.cyanAccent.shade400;
    }
  }

  String _faceForKind() {
    switch (record.characterKind) {
      case CharacterKind.flameFox:
        return ['ˇωˇ', '⌓ω⌓', '✧ω✧', '🔥ω🔥'][record.currentStageIndex];
      case CharacterKind.emberDragon:
        return ['•ᴥ•', '•ᴥ•ﾉ', '•ᴥ•✧', '🐉'][record.currentStageIndex];
      case CharacterKind.spiritBud:
        return ['･ᴗ･', '･ᴗ･✿', '･ᴗ･✧', '🌿'][record.currentStageIndex];
      case CharacterKind.cyberOwl:
        return ['0v0', '0v0✦', '0v0✧', '🦉'][record.currentStageIndex];
      case CharacterKind.aquaSlime:
        return ['･ω･', '･ω･✦', '･ω･✨', '💧'][record.currentStageIndex];
    }
  }

  void _addIdleAnimation() {
    add(
      ScaleEffect.to(
        Vector2.all(1.05),
        EffectController(
          duration: 1.6,
          reverseDuration: 1.6,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
    add(
      RotateEffect.by(
        0.05,
        EffectController(
          duration: 2.0,
          reverseDuration: 2.0,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  void _addGlow(Color color) {
    add(
      CircleComponent(
        radius: _sizeForStage() * 1.35,
        paint: Paint()..color = color.withOpacity(0.08),
        anchor: Anchor.center,
      ),
    );
  }

  void _addFlameParticles(Color color) {
    add(
      ParticleSystemComponent(
        position: Vector2.zero(),
        particle: Particle.generate(
          count: 20 + record.currentStageIndex * 5,
          lifespan: 1.2,
          generator: (i) {
            final dir = (_random.nextDouble() * pi / 2) + pi / 4;
            final speed = 40 + _random.nextDouble() * 40;
            final vx = cos(dir) * speed * (_random.nextBool() ? 1 : -1);
            final vy = -sin(dir) * speed;
            return AcceleratedParticle(
              acceleration: Vector2(0, -10),
              speed: Vector2(vx, vy),
              child: CircleParticle(
                radius: max(2, 4 - i * 0.05),
                paint: Paint()..color = color.withOpacity(0.6),
              ),
            );
          },
        ),
      ),
    );
  }
}
