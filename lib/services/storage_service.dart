import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_type.dart';

class StorageService {
  static const String _recordsKey = 'habitee_records';
  static const String _legacyRecordsKey = 'addiction_records';

  Future<List<HabitRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        prefs.getString(_recordsKey) ?? prefs.getString(_legacyRecordsKey);
    final records = jsonString == null
        ? <HabitRecord>[]
        : (json.decode(jsonString) as List<dynamic>)
            .map((json) => HabitRecord.fromJson(json))
            .toList();

    final normalized = _normalizeOrder(records);
    if (prefs.containsKey(_legacyRecordsKey)) {
      await _saveRecordsInternal(normalized, prefs);
      await prefs.remove(_legacyRecordsKey);
    } else if (!_sameOrder(records, normalized)) {
      await _saveRecordsInternal(normalized, prefs);
    }
    return normalized;
  }

  Future<void> addRecord(String type, int color) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    final newRecord = HabitRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      color: color,
      startDate: DateTime.now(),
      checkIns: [],
      memo: '',
      failureNotes: {},
      order: records.length,
    );

    records.add(newRecord);
    await _saveRecordsInternal(records, prefs);
  }

  Future<void> updateRecord(
    String recordId, {
    String? type,
    int? color,
    String? memo,
    DateTime? startDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    final index = records.indexWhere((r) => r.id == recordId);
    if (index == -1) return;

    final target = records[index];
    records[index] = target.copyWith(
      type: type,
      color: color,
      memo: memo,
      startDate: startDate,
    );

    await _saveRecordsInternal(records, prefs);
  }

  Future<void> deleteRecord(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    records.removeWhere((r) => r.id == recordId);
    await _saveRecordsInternal(records, prefs);
  }

  Future<void> updateOrder(List<HabitRecord> ordered) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = <HabitRecord>[];
    for (int i = 0; i < ordered.length; i++) {
      updated.add(ordered[i].copyWith(order: i));
    }
    await _saveRecordsInternal(updated, prefs);
  }

  Future<void> checkIn(String recordId, {DateTime? date}) async {
    await toggleFailure(recordId, date ?? DateTime.now(), comment: '');
  }

  Future<void> toggleFailure(
    String recordId,
    DateTime date, {
    required String comment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    final targetIndex = records.indexWhere((r) => r.id == recordId);
    if (targetIndex == -1) return;

    final target = records[targetIndex];
    final day = _onlyDate(date);
    final updatedList = List<DateTime>.from(target.checkIns);
    final updatedNotes = Map<String, String>.from(target.failureNotes);
    final alreadyFailed =
        target.normalizedCheckIns.any((d) => _isSameDay(d, day));
    if (alreadyFailed) {
      updatedList.removeWhere((d) => _isSameDay(d, day));
      updatedNotes.remove(day.toIso8601String());
    } else {
      updatedList.add(day);
      if (comment.isNotEmpty) {
        updatedNotes[day.toIso8601String()] = comment;
      }
    }

    records[targetIndex] = target.copyWith(
      checkIns: updatedList,
      startDate: target.startDate,
      failureNotes: updatedNotes,
    );

    await _saveRecordsInternal(records, prefs);
  }

  Future<void> _saveRecordsInternal(
      List<HabitRecord> records, SharedPreferences prefs) async {
    final jsonString = json.encode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_recordsKey, jsonString);
  }

}

List<HabitRecord> _normalizeOrder(List<HabitRecord> records) {
  final sorted = List<HabitRecord>.from(records)
    ..sort((a, b) => a.order.compareTo(b.order));
  for (int i = 0; i < sorted.length; i++) {
    sorted[i] = sorted[i].copyWith(order: i);
  }
  return sorted;
}

bool _sameOrder(List<HabitRecord> a, List<HabitRecord> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id || a[i].order != b[i].order) return false;
  }
  return true;
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);
