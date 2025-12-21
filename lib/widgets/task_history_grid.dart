import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/habit_type.dart';

class TaskHistoryGrid extends StatelessWidget {
  final HabitRecord record;
  final double cellSize;
  final double gap;

  const TaskHistoryGrid({
    super.key,
    required this.record,
    this.cellSize = 14,
    this.gap = 4,
  });

  @override
  Widget build(BuildContext context) {
    final today = _onlyDate(DateTime.now());
    final start = _onlyDate(record.startDate);
    final weekStart = _startOfWeek(start);
    final totalDays = today.difference(weekStart).inDays + 1;
    final weeks = math.max(1, (totalDays / 7).ceil());
    final failures = {
      for (final d in record.normalizedCheckIns) _onlyDate(d).toIso8601String()
    };
    final dayLabels = const ['日', '月', '火', '水', '木', '金', '土'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthRow(weekStart: weekStart, weeks: weeks, cellSize: cellSize, gap: gap),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: List.generate(7, (index) {
                  return Container(
                    width: 18,
                    height: cellSize,
                    margin: EdgeInsets.only(bottom: index == 6 ? 0 : gap),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      dayLabels[index],
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(weeks, (week) {
                  return Padding(
                    padding: EdgeInsets.only(right: week == weeks - 1 ? 0 : gap),
                    child: Column(
                      children: List.generate(7, (dayOfWeek) {
                        final idx = week * 7 + dayOfWeek;
                        final date = weekStart.add(Duration(days: idx));
                        final inRange =
                            !date.isBefore(start) && !date.isAfter(today);
                        final isFailure = failures.contains(date.toIso8601String());
                        final active = inRange && !isFailure;

                        return Container(
                          width: cellSize,
                          height: cellSize,
                          margin: EdgeInsets.only(bottom: dayOfWeek == 6 ? 0 : gap),
                          decoration: BoxDecoration(
                            color: inRange
                                ? (active
                                    ? Color(record.color)
                                    : const Color(0xFFEBEDF0))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

DateTime _onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _startOfWeek(DateTime date) {
  final offset = date.weekday % 7;
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: offset));
}

class _MonthRow extends StatelessWidget {
  final DateTime weekStart;
  final int weeks;
  final double cellSize;
  final double gap;

  const _MonthRow({
    required this.weekStart,
    required this.weeks,
    required this.cellSize,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final labels = <_MonthLabel>[];
    for (int w = 0; w < weeks; w++) {
      final date = weekStart.add(Duration(days: w * 7));
      final month = date.month;
      if (labels.isEmpty || labels.last.month != month) {
        labels.add(_MonthLabel(month: month, startWeek: w));
      }
    }
    return Row(
      children: List.generate(labels.length, (index) {
        final label = labels[index];
        final endWeek =
            index + 1 < labels.length ? labels[index + 1].startWeek : weeks;
        final weekSpan = endWeek - label.startWeek;
        final width = (weekSpan * cellSize) + ((weekSpan - 1) * gap);
        return Container(
          width: width,
          margin: EdgeInsets.only(right: index == labels.length - 1 ? 0 : gap),
          child: Text(
            '${label.month}月',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        );
      }),
    );
  }
}

class _MonthLabel {
  final int month;
  final int startWeek;

  _MonthLabel({required this.month, required this.startWeek});
}
