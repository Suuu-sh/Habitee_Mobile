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
    final bestTask = _records.reduce((a, b) =>
        a.consecutiveDays >= b.consecutiveDays ? a : b);
    final longestStreak =
        _records.map((r) => r.consecutiveDays).reduce((a, b) => a > b ? a : b);
    final successRate7d = _successRateLastDays(_records, 7);

    return Container(
      color: const Color(0xFFF4F1FA),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
        children: [
          Text(
            'Insight',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),
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
                caption: bestTask.type,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('注目タスク'),
          const SizedBox(height: 10),
          _TaskHighlightCard(record: bestTask),
          const SizedBox(height: 20),
          _SectionTitle('最近の傾向'),
          const SizedBox(height: 10),
          _TrendList(records: _records),
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

class _TaskHighlightCard extends StatelessWidget {
  final HabitRecord record;

  const _TaskHighlightCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = Color(record.color);
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.star_rounded, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.type,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.consecutiveDays}日連続',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendList extends StatelessWidget {
  final List<HabitRecord> records;

  const _TrendList({required this.records});

  @override
  Widget build(BuildContext context) {
    final sorted = List<HabitRecord>.from(records)
      ..sort((a, b) => b.consecutiveDays.compareTo(a.consecutiveDays));
    return Column(
      children: sorted.map((record) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9E9EF)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(record.color),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  record.type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${record.consecutiveDays}日',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
