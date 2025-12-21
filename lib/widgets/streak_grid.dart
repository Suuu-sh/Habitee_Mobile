import 'package:flutter/material.dart';
import '../models/habit_type.dart';

class StreakGrid extends StatelessWidget {
  final HabitRecord record;

  const StreakGrid({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final today = _onlyDate(DateTime.now());
    final activeSet = {
      for (final d in record.normalizedCheckIns) _onlyDate(d).toIso8601String()
    };

    final days = List<DateTime>.generate(
      28,
      (index) => today.subtract(Duration(days: 27 - index)),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(4, (week) {
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Column(
            children: List.generate(7, (dayOfWeek) {
              final idx = week * 7 + dayOfWeek;
              final date = days[idx];
              final hasCheckIn = activeSet.contains(date.toIso8601String());
              final intensity =
                  (1 - (today.difference(date).inDays / 28)).clamp(0.0, 1.0);
              final color = hasCheckIn
                  ? Color.lerp(Colors.green.shade300, Colors.green.shade800, intensity)!
                  : Colors.grey.shade200;

              return Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                  ),
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
