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
        _records.map((r) => r.longestStreak).reduce((a, b) => a > b ? a : b);
    final successRate7d = _successRateLastDays(_records, 7);
    final weekTrend = _weeklySuccessTrend(_records, 6);
    final weekLabels = _weeklyLabels(weekTrend.length);
    final monthTrend = _monthlySuccessTrend(_records, 6);
    final monthLabels = _monthlyLabels(monthTrend.length);
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
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            const SizedBox(height: 8),
            _StatRow(
              children: [
                _StatCard(
                  title: 'タスク数',
                  value: '$totalTasks',
                  caption: 'アクティブ',
                  icon: Icons.task_alt_rounded,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: '平均継続',
                  value: '$avgStreak日',
                  caption: '現在の連続',
                  icon: Icons.trending_up_rounded,
                  color: Colors.green,
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
                  icon: Icons.percent_rounded,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: '最高記録',
                  value: '$longestStreak日',
                  caption: 'ベスト継続',
                  icon: Icons.emoji_events_rounded,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionTitle('週ごとの達成率', Icons.calendar_view_week_rounded),
            const SizedBox(height: 12),
            _BarChart(
              values: weekTrend,
              unitLabel: '%',
              caption: '直近6週',
              labels: weekLabels,
            ),
            const SizedBox(height: 24),
            _SectionTitle('月ごとの達成率', Icons.calendar_month_rounded),
            const SizedBox(height: 12),
            _BarChart(
              values: monthTrend,
              unitLabel: '%',
              caption: '直近6ヶ月',
              labels: monthLabels,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildEmptyState(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  
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
            ),
            child: const Text('📈', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 24),
          const Text(
            'データがありません',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'タスクを追加して継続すると\nインサイトが表示されます',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
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
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height < 1 ? 1 : height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: height >= 24
                              ? Text(
                                  '${value.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
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
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
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
