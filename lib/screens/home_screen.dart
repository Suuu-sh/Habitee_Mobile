import 'package:flutter/material.dart';
import '../models/habit_type.dart';
import '../services/storage_service.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final int refreshToken;
  final VoidCallback? onFailureRecorded;

  const HomeScreen({
    super.key,
    this.refreshToken = 0,
    this.onFailureRecorded,
  });

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

  Future<void> _toggleFailure(
    HabitRecord record,
    DateTime date,
    bool alreadyFailed,
  ) async {
    if (alreadyFailed) {
      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('失敗の記録を取り消しますか？'),
            content: const Text('この日の失敗記録を削除します。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('取り消す'),
              ),
            ],
          );
        },
      );
      if (shouldClear != true) return;
      await _storage.toggleFailure(record.id, date, comment: '');
      await _loadRecords();
      widget.onFailureRecorded?.call();
      return;
    }

    final controller = TextEditingController();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('今日は失敗しましたか？'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('理由を入力してください。'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '例: 予定が詰まっていた',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('記録する'),
            ),
          ],
        );
      },
    );
    if (shouldSave != true) return;
    await _storage.toggleFailure(
      record.id,
      date,
      comment: controller.text.trim(),
    );
    await _loadRecords();
    widget.onFailureRecorded?.call();
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

  Future<void> _reorderTasks(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final updated = List<HabitRecord>.from(_records);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    setState(() {
      _records = updated;
    });
    await _storage.updateOrder(updated);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF4F1FA),
      appBar: null,
      body: _records.isEmpty
          ? _buildEmptyState()
          : SafeArea(
              child: _WeeklyTracker(
                records: _records,
                onToggleFailure: _toggleFailure,
                onOpenTask: _openTask,
                onReorder: _reorderTasks,
              ),
            ),
      floatingActionButton: null,
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withOpacity(0.05),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Text(
                '🌱',
                style: TextStyle(fontSize: 80),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'まだ記録がありません',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '下のボタンから始めましょう',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTracker() {
    return _WeeklyTracker(
      records: _records,
      onToggleFailure: _toggleFailure,
      onOpenTask: _openTask,
      onReorder: _reorderTasks,
    );
  }
}

class _WeeklyTracker extends StatefulWidget {
  final List<HabitRecord> records;
  final Future<void> Function(
    HabitRecord record,
    DateTime date,
    bool alreadyFailed,
  ) onToggleFailure;
  final Future<void> Function(HabitRecord record) onOpenTask;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;

  const _WeeklyTracker({
    required this.records,
    required this.onToggleFailure,
    required this.onOpenTask,
    required this.onReorder,
  });

  @override
  State<_WeeklyTracker> createState() => _WeeklyTrackerState();
}

class _WeeklyTrackerState extends State<_WeeklyTracker> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _startOfWeek(DateTime.now());
  }

  void _shiftWeek(int delta) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: delta * 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List<DateTime>.generate(
      7,
      (index) => _weekStart.add(Duration(days: index)),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withOpacity(0.05),
            isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF4F1FA),
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _WeekHeader(
                days: days,
                today: today,
                onPrev: () => _shiftWeek(-1),
                onNext: () => _shiftWeek(1),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: widget.records.length,
              onReorder: widget.onReorder,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final record = widget.records[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(record.id),
                  index: index,
                  child: TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(record.color)
                                .withOpacity(isDark ? 0.25 : 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => widget.onOpenTask(record),
                        child: _TaskRow(
                          record: record,
                          days: days,
                          today: today,
                          onToggleFailure: widget.onToggleFailure,
                          onOpenTask: () => widget.onOpenTask(record),
                        ),
                      ),
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
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _WeekHeader({
    required this.days,
    required this.today,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _monthLabel(days),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 6),
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

String _monthLabel(List<DateTime> days) {
  final start = days.first;
  final end = days.last;
  if (start.month == end.month) {
    return '${start.year}年${start.month}月';
  }
  return '${start.year}年${start.month}月 - ${end.month}月';
}

class _TaskRow extends StatelessWidget {
  final HabitRecord record;
  final List<DateTime> days;
  final DateTime today;
  final Future<void> Function(
    HabitRecord record,
    DateTime date,
    bool alreadyFailed,
  ) onToggleFailure;
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(record.color),
                      Color(record.color).withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${record.consecutiveDays}日継続中',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ベスト ${record.longestStreak}日',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                    ? () => onToggleFailure(record, date, failed)
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
    final isSunday = date.weekday == DateTime.sunday;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Text(
          _weekdayLabel(date.weekday),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSunday
                ? Colors.red[400]
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isToday
                ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  )
                : null,
            color: isToday ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isToday ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
            ),
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
    final baseColor = Color(color);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                colors: [
                  baseColor,
                  baseColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active
            ? null
            : (isDisabled 
                ? (isDark ? Colors.grey[800] : Colors.grey[100])
                : (isDark ? Colors.grey[700] : Colors.grey[200])),
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
        boxShadow: active
            ? [
                BoxShadow(
                  color: baseColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: active
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 16,
            )
          : null,
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
