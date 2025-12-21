class HabitRecord {
  final String id;
  final String type;
  final int color;
  final DateTime startDate;
  final List<DateTime> checkIns;
  final String memo;

  HabitRecord({
    required this.id,
    required this.type,
    required this.color,
    required this.startDate,
    required this.checkIns,
    required this.memo,
  });

  List<DateTime> get normalizedCheckIns {
    return _normalizeDates(checkIns);
  }

  DateTime? get lastCheckIn {
    final dates = normalizedCheckIns;
    if (dates.isEmpty) return null;
    return dates.last;
  }

  int get consecutiveDays {
    final today = _onlyDate(DateTime.now());
    final start = _onlyDate(startDate);
    if (today.isBefore(start)) return 0;
    final failures = {for (final d in normalizedCheckIns) d.toIso8601String()};
    int streak = 0;
    for (var d = today; !d.isBefore(start); d = d.subtract(const Duration(days: 1))) {
      if (failures.contains(d.toIso8601String())) {
        break;
      }
      streak += 1;
    }
    return streak;
  }

  HabitRecord copyWith({
    List<DateTime>? checkIns,
    DateTime? startDate,
    int? color,
    String? type,
    String? memo,
  }) {
    return HabitRecord(
      id: id,
      type: type ?? this.type,
      color: color ?? this.color,
      startDate: startDate ?? this.startDate,
      checkIns: checkIns ?? this.checkIns,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'color': color,
        'tracking': 'auto',
        'startDate': startDate.toIso8601String(),
        'checkIns': normalizedCheckIns.map((d) => d.toIso8601String()).toList(),
        'memo': memo,
      };

  factory HabitRecord.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final color = json['color'] as int? ?? 0xFF40C463;
    final start = DateTime.parse(json['startDate']);
    final tracking = json['tracking'] as String?;
    final memo = json['memo'] as String? ?? '';

    // 旧フォーマット(daysClean)からのマイグレーション
    if (json['checkIns'] == null && json['daysClean'] != null) {
      final daysClean = json['daysClean'] as int;
      final generated = List<DateTime>.generate(
        daysClean,
        (index) => _onlyDate(start.add(Duration(days: index))),
      );
      final failures = _invertDays(start, generated);
      return HabitRecord(
        id: json['id'],
        type: type,
        color: color,
        startDate: start,
        checkIns: failures,
        memo: memo,
      );
    }

    final rawList = (json['checkIns'] as List<dynamic>? ?? [])
        .map((e) => DateTime.parse(e as String))
        .toList();
    final normalized = _normalizeDates(rawList);
    final failures =
        tracking == 'auto' ? normalized : _invertDays(start, normalized);

    return HabitRecord(
      id: json['id'],
      type: type,
      color: color,
      startDate: start,
      checkIns: failures,
      memo: memo,
    );
  }
}

DateTime _onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);

List<DateTime> _normalizeDates(List<DateTime> dates) {
  final seen = <String>{};
  final result = <DateTime>[];
  for (final date in dates) {
    final d = _onlyDate(date);
    final key = d.toIso8601String();
    if (seen.add(key)) {
      result.add(d);
    }
  }
  result.sort((a, b) => a.compareTo(b));
  return result;
}

List<DateTime> _invertDays(DateTime start, List<DateTime> successes) {
  final today = _onlyDate(DateTime.now());
  final startDay = _onlyDate(start);
  if (today.isBefore(startDay)) return [];
  final successSet = {for (final d in successes) d.toIso8601String()};
  final failures = <DateTime>[];
  for (var d = today; !d.isBefore(startDay); d = d.subtract(const Duration(days: 1))) {
    final key = d.toIso8601String();
    if (!successSet.contains(key)) {
      failures.add(d);
    }
  }
  return failures;
}
