import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/habit_type.dart';
import 'character_component.dart';

class CharacterGame extends FlameGame {
  final HabitRecord record;

  CharacterGame({required this.record});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.center;

    final character = CharacterComponent(
      record: record,
      position: size / 2,
    );
    
    await add(character);
  }

  @override
  Color backgroundColor() => const Color(0xFFF5F5F5);
}
