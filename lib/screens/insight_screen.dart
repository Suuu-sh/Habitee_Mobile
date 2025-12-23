import 'package:flutter/material.dart';
import '../models/habit_type.dart';
import '../services/storage_service.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  final StorageService _storage = StorageService();
  List<HabitRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _storage.getRecords();
    setState(() {
      _records = records;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_records.isEmpty) {
      return _buildEmptyState(context);
    }

    final totalTasks = _records.length;
    final avgStreak =
        (_records.map((r) => r.consecutiveDays).reduce((a, b) => a + b) /
                totalTasks)
            .toStringAsFixed(1);
    final longestStreak =
        _records.map((r) => r.consecutiveDays).reduce((a, b) => a > b ? a : b);
    final successRate7d = _successRateLastDays(_records, 7);
    final weekTrend = _weeklySuccessTrend(_records, 6);
    final weekLabels = _weeklyLabels(weekTrend.length);
    final monthTrend = _monthlySuccessTrend(_records, 6);
    final monthLabels = _monthlyLabels(monthTrend.length);

    return Container(
      color: const Color(0xFFF4F1FA),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
        children: [
          const SizedBox(height: 4),
          _StatRow(
            children: [
              _StatCard(
                title: 'タスク数',
                value: '$totalTasks',
                caption: 'アクティブ',
              ),
              _StatCard(
                title: '平均継続',
                value: '$avgStreak日',
                caption: '現在の連続',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatRow(
            children: [
              _StatCard(
                title: '直近7日達成率',
                value: '${successRate7d.toStringAsFixed(0)}%',
                caption: '全タスク平均',
              ),
              _StatCard(
                title: '最高継続',
                value: '$longestStreak日',
                caption: '現在の連続',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('週ごとの達成率'),
          const SizedBox(height: 10),
          _BarChart(
            values: weekTrend,
            unitLabel: '%',
            caption: '直近6週',
            labels: weekLabels,
          ),
          const SizedBox(height: 20),
          _SectionTitle('月ごとの達成率'),
          const SizedBox(height: 10),
          _BarChart(
            values: monthTrend,
            unitLabel: '%',
            caption: '直近6ヶ月',
            labels: monthLabels,
          ),
        ],
      ),
    );
  }
}

Widget _buildEmptyState(BuildContext context) {
  return Container(
    color: const Color(0xFFF4F1FA),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📈', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'データがありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'タスクを追加して継続すると\nインサイトが表示されます',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}

double _successRateLastDays(List<HabitRecord> records, int days) {
  final today = _onlyDate(DateTime.now());
  int totalTracked = 0;
  int totalSuccess = 0;
  for (final record in records) {
    final start = _onlyDate(record.startDate);
    final failures = {
      for (final d in record.normalizedCheckIns) _onlyDate(d).toIso8601String()
    };
    for (int i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.isBefore(start)) continue;
      totalTracked += 1;
      final failed = failures.contains(day.toIso8601String());
      if (!failed) totalSuccess += 1;
    }
  }
  if (totalTracked == 0) return 0;
  return (totalSuccess / totalTracked) * 100;
}

DateTime _onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);

class _StatRow extends StatelessWidget {
  final List<Widget> children;

  const _StatRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .map((child) => Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: child,
              )))
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;

  const _StatCard({
    required this.title,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<double> values;
  final String unitLabel;
  final String caption;
  final List<String> labels;

  const _BarChart({
    required this.values,
    required this.unitLabel,
    required this.caption,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: values.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;
                final height = (value / maxValue).clamp(0.0, 1.0) * 120;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              height: height,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            if (height >= 24)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '${value.toStringAsFixed(0)}$unitLabel',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 24,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              labels.isNotEmpty && index < labels.length
                                  ? labels[index]
                                  : '${index + 1}',
                              style: TextStyle(
                                fontSize: 7,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

List<double> _weeklySuccessTrend(List<HabitRecord> records, int weeks) {
  final today = _onlyDate(DateTime.now());
  final results = <double>[];
  for (int w = weeks - 1; w >= 0; w--) {
    final end = today.subtract(Duration(days: w * 7));
    final start = end.subtract(const Duration(days: 6));
    results.add(_successRateForRange(records, start, end));
  }
  return results;
}

List<double> _monthlySuccessTrend(List<HabitRecord> records, int months) {
  final now = DateTime.now();
  final results = <double>[];
  for (int i = months - 1; i >= 0; i--) {
    final target = DateTime(now.year, now.month - i, 1);
    final start = _onlyDate(target);
    final end = _onlyDate(DateTime(target.year, target.month + 1, 0));
    results.add(_successRateForRange(records, start, end));
  }
  return results;
}

double _successRateForRange(
  List<HabitRecord> records,
  DateTime start,
  DateTime end,
) {
  int totalTracked = 0;
  int totalSuccess = 0;
  for (final record in records) {
    final recordStart = _onlyDate(record.startDate);
    final failures = {
      for (final d in record.normalizedCheckIns) _onlyDate(d).toIso8601String()
    };
    for (var d = end; !d.isBefore(start); d = d.subtract(const Duration(days: 1))) {
      if (d.isBefore(recordStart)) continue;
      totalTracked += 1;
      final failed = failures.contains(d.toIso8601String());
      if (!failed) totalSuccess += 1;
    }
  }
  if (totalTracked == 0) return 0;
  return (totalSuccess / totalTracked) * 100;
}

String _formatShort(DateTime date) {
  return '${date.month}/${date.day}';
}

List<String> _weeklyLabels(int weeks) {
  if (weeks <= 0) return [];
  final today = _onlyDate(DateTime.now());
  final labels = <String>[];
  for (int w = weeks - 1; w >= 0; w--) {
    final end = today.subtract(Duration(days: w * 7));
    final start = end.subtract(const Duration(days: 6));
    labels.add('${_formatShort(start)}~${_formatShort(end)}');
  }
  return labels;
}

List<String> _monthlyLabels(int months) {
  if (months <= 0) return [];
  final now = DateTime.now();
  final labels = <String>[];
  for (int i = months - 1; i >= 0; i--) {
    final target = DateTime(now.year, now.month - i, 1);
    labels.add('${target.month}月');
  }
  return labels;
}
