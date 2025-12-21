import 'package:flutter/material.dart';
import '../models/habit_type.dart';
import '../services/storage_service.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final int refreshToken;

  const HomeScreen({super.key, this.refreshToken = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<HabitRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    final records = await _storage.getRecords();
    setState(() {
      _records = records;
    });
  }

  Future<void> _toggleFailure(String recordId, DateTime date) async {
    await _storage.toggleFailure(recordId, date);
    await _loadRecords();
  }

  Future<void> _openTask(HabitRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(record: record),
      ),
    );
    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1FA),
      appBar: null,
      body: _records.isEmpty
          ? _buildEmptyState()
          : SafeArea(
              child: _WeeklyTracker(
                records: _records,
                onToggleFailure: _toggleFailure,
                onOpenTask: _openTask,
              ),
            ),
      floatingActionButton: null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'まだ記録がありません',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            '下のボタンから始めましょう',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTracker() {
    return _WeeklyTracker(
      records: _records,
      onToggleFailure: _toggleFailure,
      onOpenTask: _openTask,
    );
  }
}

class _WeeklyTracker extends StatelessWidget {
  final List<HabitRecord> records;
  final Future<void> Function(String recordId, DateTime date) onToggleFailure;
  final Future<void> Function(HabitRecord record) onOpenTask;

  _WeeklyTracker({
    required this.records,
    required this.onToggleFailure,
    required this.onOpenTask,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekStart = _startOfWeek(today);
    final days = List<DateTime>.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    return Container(
      color: const Color(0xFFF4F1FA),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _WeekHeader(days: days, today: today),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final record = records[index];
                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8EAE5)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onOpenTask(record),
                    child: _TaskRow(
                      record: record,
                      days: days,
                      today: today,
                      onToggleFailure: onToggleFailure,
                      onOpenTask: () => onOpenTask(record),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final List<DateTime> days;
  final DateTime today;

  const _WeekHeader({required this.days, required this.today});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(days.length, (index) {
                  final date = days[index];
                  return _DayHeaderCell(date: date, today: today);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final HabitRecord record;
  final List<DateTime> days;
  final DateTime today;
  final Future<void> Function(String recordId, DateTime date) onToggleFailure;
  final VoidCallback onOpenTask;

  const _TaskRow({
    required this.record,
    required this.days,
    required this.today,
    required this.onToggleFailure,
    required this.onOpenTask,
  });

  @override
  Widget build(BuildContext context) {
    final activeSet = {
      for (final d in record.normalizedCheckIns)
        DateTime(d.year, d.month, d.day).toIso8601String()
    };

    final startDate = DateTime(
      record.startDate.year,
      record.startDate.month,
      record.startDate.day,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.type,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (index) {
              final date = days[index];
              final key = DateTime(date.year, date.month, date.day)
                  .toIso8601String();
              final isFuture = date.isAfter(today);
              final isBeforeStart = date.isBefore(startDate);
              final isTracked = !(isFuture || isBeforeStart);
              final failed = activeSet.contains(key);
              final active = isTracked && !failed;
              final isToday = _isSameDay(date, today);
              return GestureDetector(
                onTap: isTracked
                    ? () => onToggleFailure(record.id, date)
                    : null,
                child: _DayDot(
                  active: active,
                  isToday: isToday,
                  isDisabled: !isTracked,
                  color: record.color,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  final DateTime date;
  final DateTime today;

  const _DayHeaderCell({required this.date, required this.today});

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, today);
    return Column(
      children: [
        Text(
          _weekdayLabel(date.weekday),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: date.weekday == DateTime.sunday
                ? Colors.red[300]
                : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFE9F5EE) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToday ? const Color(0xFF2D6A4F) : Colors.transparent,
            ),
          ),
          child: Text(
            '${date.day}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  final bool active;
  final bool isToday;
  final bool isDisabled;
  final int color;

  const _DayDot({
    required this.active,
    required this.isToday,
    required this.isDisabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active
            ? Color(color)
            : (isDisabled ? const Color(0xFFF3F3F3) : const Color(0xFFEBEDF0)),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isToday ? const Color(0xFF2D6A4F) : Colors.transparent,
          width: isToday ? 1.2 : 1,
        ),
      ),
    );
  }
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.sunday:
      return '日';
    case DateTime.monday:
      return '月';
    case DateTime.tuesday:
      return '火';
    case DateTime.wednesday:
      return '水';
    case DateTime.thursday:
      return '木';
    case DateTime.friday:
      return '金';
    case DateTime.saturday:
      return '土';
    default:
      return '';
  }
}

DateTime _startOfWeek(DateTime date) {
  final offset = date.weekday % 7;
  final start = DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: offset));
  return start;
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
