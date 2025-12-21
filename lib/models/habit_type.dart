enum HabitType {
  gambling('ギャンブル', '🎰'),
  alcohol('お酒', '🍺'),
  smoking('タバコ', '🚬'),
  gaming('ゲーム', '🎮'),
  shopping('買い物', '🛍️'),
  social_media('SNS', '📱');

  final String displayName;
  final String emoji;

  const HabitType(this.displayName, this.emoji);
}

enum CharacterKind {
  flameFox('フレイムフォックス'),
  emberDragon('エンバードラゴン'),
  spiritBud('スピリットバッド'),
  cyberOwl('サイバーアウル'),
  aquaSlime('アクアスライム');

  final String displayName;

  const CharacterKind(this.displayName);
}

class CollectedCharacter {
  final String id;
  final HabitType type;
  final CharacterKind characterKind;
  final int stageIndex; // 0-3 (週1-週4の姿)
  final DateTime collectedAt;

  CollectedCharacter({
    required this.id,
    required this.type,
    required this.characterKind,
    required this.stageIndex,
    required this.collectedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'characterKind': characterKind.name,
        'stageIndex': stageIndex,
        'collectedAt': collectedAt.toIso8601String(),
      };

  factory CollectedCharacter.fromJson(Map<String, dynamic> json) =>
      CollectedCharacter(
        id: json['id'],
        type: HabitType.values.firstWhere((e) => e.name == json['type']),
        characterKind:
            CharacterKind.values.firstWhere((e) => e.name == json['characterKind']),
        stageIndex: json['stageIndex'] ?? 0,
        collectedAt: DateTime.parse(json['collectedAt']),
      );
}

class HabitRecord {
  final String id;
  final HabitType type;
  final CharacterKind characterKind;
  final DateTime startDate;
  final List<DateTime> checkIns;

  HabitRecord({
    required this.id,
    required this.type,
    required this.characterKind,
    required this.startDate,
    required this.checkIns,
  });

  List<DateTime> get normalizedCheckIns {
    final seen = <String>{};
    final result = <DateTime>[];
    for (final date in checkIns) {
      final d = _onlyDate(date);
      final key = d.toIso8601String();
      if (seen.add(key)) {
        result.add(d);
      }
    }
    result.sort((a, b) => a.compareTo(b));
    return result;
  }

  DateTime? get lastCheckIn {
    final dates = normalizedCheckIns;
    if (dates.isEmpty) return null;
    return dates.last;
  }

  int get consecutiveDays {
    final dates = normalizedCheckIns;
    if (dates.isEmpty) return 0;
    int streak = 1;
    for (int i = dates.length - 1; i > 0; i--) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff == 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  int get completedWeeks => (consecutiveDays ~/ 7).clamp(0, 4);

  int get currentStageIndex => completedWeeks.clamp(0, 3);

  bool get isCleared => consecutiveDays >= 28;

  bool get hasBrokenStreak {
    final last = lastCheckIn;
    if (last == null) return false;
    return DateTime.now().difference(last).inDays > 1 && consecutiveDays > 0;
  }

  String get stageLabel {
    switch (currentStageIndex) {
      case 0:
        return '週1';
      case 1:
        return '週2';
      case 2:
        return '週3';
      case 3:
        return '週4';
      default:
        return '週1';
    }
  }

  HabitRecord copyWith({
    List<DateTime>? checkIns,
    DateTime? startDate,
  }) {
    return HabitRecord(
      id: id,
      type: type,
      characterKind: characterKind,
      startDate: startDate ?? this.startDate,
      checkIns: checkIns ?? this.checkIns,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'characterKind': characterKind.name,
        'startDate': startDate.toIso8601String(),
        'checkIns': normalizedCheckIns.map((d) => d.toIso8601String()).toList(),
      };

  factory HabitRecord.fromJson(Map<String, dynamic> json) {
    final type =
        HabitType.values.firstWhere((e) => e.name == json['type']);
    final start = DateTime.parse(json['startDate']);
    final characterKind = json['characterKind'] != null
        ? CharacterKind.values
            .firstWhere((e) => e.name == json['characterKind'])
        : CharacterKind.values[start.millisecondsSinceEpoch %
            CharacterKind.values.length];

    // 旧フォーマット(daysClean)からのマイグレーション
    if (json['checkIns'] == null && json['daysClean'] != null) {
      final daysClean = json['daysClean'] as int;
      final generated = List<DateTime>.generate(
        daysClean,
        (index) => _onlyDate(start.add(Duration(days: index))),
      );
      return HabitRecord(
        id: json['id'],
        type: type,
        characterKind: characterKind,
        startDate: start,
        checkIns: generated,
      );
    }

    final rawList = (json['checkIns'] as List<dynamic>? ?? [])
        .map((e) => DateTime.parse(e as String))
        .toList();

    return HabitRecord(
      id: json['id'],
      type: type,
      characterKind: characterKind,
      startDate: start,
      checkIns: rawList,
    );
  }
}

DateTime _onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);
