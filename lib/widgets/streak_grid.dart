import 'package:flutter/material.dart';
import '../models/habit_type.dart';

class StreakGrid extends StatelessWidget {
  final HabitRecord record;
  final int weeks;
  final double cellSize;
  final double gap;

  const StreakGrid({
    super.key,
    required this.record,
    this.weeks = 4,
    this.cellSize = 18,
    this.gap = 4,
  });

  @override
  Widget build(BuildContext context) {
    final today = _onlyDate(DateTime.now());
    final activeSet = {
      for (final d in record.normalizedCheckIns) _onlyDate(d).toIso8601String()
    };

    final totalDays = weeks * 7;
    final days = List<DateTime>.generate(
      totalDays,
      (index) => today.subtract(Duration(days: totalDays - 1 - index)),
    );

    const inactiveColor = Color(0xFFEBEDF0);
    const activeColor = Color(0xFF40C463);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(weeks, (week) {
        return Padding(
          padding: EdgeInsets.only(right: week == weeks - 1 ? 0 : gap),
          child: Column(
            children: List.generate(7, (dayOfWeek) {
              final idx = week * 7 + dayOfWeek;
              final date = days[idx];
              final hasCheckIn = activeSet.contains(date.toIso8601String());
              final color = hasCheckIn
                  ? activeColor
                  : inactiveColor;

              return Container(
                width: cellSize,
                height: cellSize,
                margin: EdgeInsets.only(bottom: dayOfWeek == 6 ? 0 : gap),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

DateTime _onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);
