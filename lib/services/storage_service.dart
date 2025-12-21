import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_type.dart';

class StorageService {
  static const String _recordsKey = 'habitee_records';
  static const String _legacyRecordsKey = 'addiction_records';
  static const String _collectionKey = 'collected_characters';

  Future<List<HabitRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        prefs.getString(_recordsKey) ?? prefs.getString(_legacyRecordsKey);
    final records = jsonString == null
        ? <HabitRecord>[]
        : (json.decode(jsonString) as List<dynamic>)
            .map((json) => HabitRecord.fromJson(json))
            .toList();

    final processed = await _processRecords(records, prefs);
    if (prefs.containsKey(_legacyRecordsKey)) {
      await _saveRecordsInternal(processed, prefs);
      await prefs.remove(_legacyRecordsKey);
    }
    return processed;
  }

  Future<List<CollectedCharacter>> getCollection() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_collectionKey);
    if (jsonString == null) return [];
    return (json.decode(jsonString) as List<dynamic>)
        .map((json) => CollectedCharacter.fromJson(json))
        .toList();
  }

  Future<void> addRecord(HabitType type) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    final kind = CharacterKind.values[Random().nextInt(CharacterKind.values.length)];
    final newRecord = HabitRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      characterKind: kind,
      startDate: DateTime.now(),
      checkIns: [],
    );

    records.add(newRecord);
    await _saveRecordsInternal(records, prefs);
  }

  Future<void> checkIn(String recordId, {DateTime? date}) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    final targetIndex = records.indexWhere((r) => r.id == recordId);
    if (targetIndex == -1) return;

    final target = records[targetIndex];
    final today = _onlyDate(date ?? DateTime.now());
    final updatedList = List<DateTime>.from(target.checkIns);
    final alreadyChecked = target.normalizedCheckIns.any((d) => _isSameDay(d, today));
    if (!alreadyChecked) {
      updatedList.add(today);
    }

    records[targetIndex] = target.copyWith(
      checkIns: updatedList,
      startDate: target.startDate,
    );

    final processed = await _processRecords(records, prefs);
    await _saveRecordsInternal(processed, prefs);
  }

  Future<void> _saveRecordsInternal(
      List<HabitRecord> records, SharedPreferences prefs) async {
    final jsonString = json.encode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_recordsKey, jsonString);
  }

  Future<void> _saveCollectionInternal(
      List<CollectedCharacter> collection, SharedPreferences prefs) async {
    final jsonString = json.encode(collection.map((c) => c.toJson()).toList());
    await prefs.setString(_collectionKey, jsonString);
  }

  Future<List<HabitRecord>> _processRecords(
    List<HabitRecord> records,
    SharedPreferences prefs,
  ) async {
    final updated = <HabitRecord>[];
    final collection = await getCollection();
    bool changed = false;

    for (final record in records) {
      int? stageToCollect;

      if (record.isCleared) {
        stageToCollect = 3;
      } else if (record.hasBrokenStreak) {
        final completedWeeks = record.completedWeeks;
        if (completedWeeks > 0) {
          stageToCollect = (completedWeeks - 1).clamp(0, 3);
        }
      }

      if (stageToCollect != null) {
        collection.add(
          CollectedCharacter(
            id: '${record.id}-${DateTime.now().millisecondsSinceEpoch}',
            type: record.type,
            characterKind: record.characterKind,
            stageIndex: stageToCollect,
            collectedAt: DateTime.now(),
          ),
        );
        updated.add(
          record.copyWith(
            checkIns: [],
            startDate: DateTime.now(),
          ),
        );
        changed = true;
      } else {
        updated.add(record);
      }
    }

    if (changed) {
      await _saveRecordsInternal(updated, prefs);
      await _saveCollectionInternal(collection, prefs);
    }

    return updated;
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);
