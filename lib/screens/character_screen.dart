import 'package:flutter/material.dart';
import '../models/habit_type.dart';
import '../services/storage_service.dart';
import '../widgets/streak_grid.dart';

class CharacterScreen extends StatefulWidget {
  final HabitRecord record;

  const CharacterScreen({super.key, required this.record});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  final StorageService _storage = StorageService();
  late HabitRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _refresh();
  }

  Future<void> _refresh() async {
    final records = await _storage.getRecords();
    final latest = records.firstWhere(
      (r) => r.id == _record.id,
      orElse: () => _record,
    );
    setState(() {
      _record = latest;
    });
  }

  Future<void> _checkInToday() async {
    await _storage.checkIn(_record.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final hasCheckedToday = _record.normalizedCheckIns
        .any((d) => _isSameDay(d, DateTime.now()));
    final daysIntoWeek = _record.consecutiveDays % 7;
    final daysToNextStage = daysIntoWeek == 0 ? 7 : 7 - daysIntoWeek;

    return Scaffold(
      appBar: AppBar(
        title: Text(_record.type.displayName),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_record.consecutiveDays}日連続',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '成長段階: ${_record.stageLabel} / 週4でクリア',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '次の成長まであと ${_record.isCleared ? 0 : daysToNextStage} 日',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: hasCheckedToday ? null : _checkInToday,
                  icon: const Icon(Icons.local_fire_department_outlined),
                  label: Text(hasCheckedToday ? '今日はチェック済み' : '今日のチェックイン'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '直近8週間の継続',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreakGrid(
                        record: _record,
                        weeks: 8,
                        cellSize: 18,
                        gap: 4,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Text(
                            'Less',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(width: 6),
                          _LegendSwatch(color: Color(0xFFEBEDF0)),
                          SizedBox(width: 4),
                          _LegendSwatch(color: Color(0xFF9BE9A8)),
                          SizedBox(width: 4),
                          _LegendSwatch(color: Color(0xFF40C463)),
                          SizedBox(width: 4),
                          _LegendSwatch(color: Color(0xFF30A14E)),
                          SizedBox(width: 4),
                          _LegendSwatch(color: Color(0xFF216E39)),
                          SizedBox(width: 6),
                          Text(
                            'More',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1週間ごとに進捗がまとまります。4週間続ければコレクションに保存されます。',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _LegendSwatch extends StatelessWidget {
  final Color color;

  const _LegendSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
