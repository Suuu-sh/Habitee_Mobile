import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/habit_type.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  final ValueListenable<int>? refreshListenable;

  const HistoryScreen({super.key, this.refreshListenable});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storage = StorageService();
  List<_FailureEntry> _entries = [];
  String? _selectedTask;
  List<String> _taskOptions = [];
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _load();
    widget.refreshListenable?.addListener(_load);
  }

  Future<void> _load() async {
    final records = await _storage.getRecords();
    final entries = <_FailureEntry>[];
    final tasks = <String>[];
    for (final record in records) {
      tasks.add(record.type);
      record.failureNotes.forEach((dateKey, comment) {
        entries.add(
          _FailureEntry(
            recordId: record.id,
            taskName: record.type,
            color: record.color,
            date: DateTime.parse(dateKey),
            comment: comment,
          ),
        );
      });
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _entries = entries;
      _taskOptions = tasks.toSet().toList()..sort();
      if (_selectedTask != null &&
          !_taskOptions.contains(_selectedTask)) {
        _selectedTask = null;
      }
    });
  }

  @override
  void dispose() {
    widget.refreshListenable?.removeListener(_load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleEntries = _entries.where((entry) {
      if (_selectedTask != null && entry.taskName != _selectedTask) {
        return false;
      }
      if (_rangeStart != null &&
          entry.date.isBefore(_onlyDate(_rangeStart!))) {
        return false;
      }
      if (_rangeEnd != null &&
          entry.date.isAfter(_onlyDate(_rangeEnd!))) {
        return false;
      }
      return true;
    }).toList();
    
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
      child: _entries.isEmpty
          ? _buildEmptyState(context)
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                    child: _FilterBar(
                      taskLabel: _selectedTask ?? 'すべて',
                      rangeLabel: _formatRange(_rangeStart, _rangeEnd),
                      onTap: _openFilterSheet,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: visibleEntries.length,
                      itemBuilder: (context, index) {
                        final entry = visibleEntries[index];
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 200 + (index * 30)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(entry.color).withOpacity(isDark ? 0.2 : 0.12),
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
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(entry.color),
                                            Color(entry.color).withOpacity(0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.event_busy_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.taskName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(entry.color).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _formatDate(entry.date),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(entry.color),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey[850]
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.comment_rounded,
                                        size: 16,
                                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.comment,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

Widget _buildEmptyState(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Text('🗂️', style: TextStyle(fontSize: 64)),
        ),
        const SizedBox(height: 24),
        const Text(
          '失敗の記録はまだありません',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'タスクを失敗した時に\nメモを残すことができます',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime date) {
  return '${date.year}/${date.month}/${date.day}';
}

class _FailureEntry {
  final String recordId;
  final String taskName;
  final int color;
  final DateTime date;
  final String comment;

  _FailureEntry({
    required this.recordId,
    required this.taskName,
    required this.color,
    required this.date,
    required this.comment,
  });
}

DateTime _onlyDate(DateTime date) => DateTime(date.year, date.month, date.day);

class _FilterBar extends StatelessWidget {
  final String taskLabel;
  final String rangeLabel;
  final VoidCallback onTap;

  const _FilterBar({
    required this.taskLabel,
    required this.rangeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$taskLabel / $rangeLabel',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

extension on _HistoryScreenState {
  Future<void> _openFilterSheet() async {
    String? tempTask = _selectedTask;
    DateTime? tempStart = _rangeStart;
    DateTime? tempEnd = _rangeEnd;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary, colorScheme.secondary],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.filter_list_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'フィルター',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'タスク',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: tempTask,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('すべて'),
                        ),
                        ..._taskOptions.map(
                          (task) => DropdownMenuItem<String?>(
                            value: task,
                            child: Text(task),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() => tempTask = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '期間',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          initialDateRange: tempStart != null && tempEnd != null
                              ? DateTimeRange(start: tempStart!, end: tempEnd!)
                              : null,
                        );
                        if (picked != null) {
                          setModalState(() {
                            tempStart = picked.start;
                            tempEnd = picked.end;
                          });
                        }
                      },
                      icon: Icon(Icons.calendar_month_rounded, color: colorScheme.primary),
                      label: Text(_formatRange(tempStart, tempEnd)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempTask = null;
                                tempStart = null;
                                tempEnd = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('クリア'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('適用'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() {
        _selectedTask = tempTask;
        _rangeStart = tempStart;
        _rangeEnd = tempEnd;
      });
    }
  }
}

String _formatRange(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '期間指定なし';
  return '${start.year}/${start.month}/${start.day} - ${end.year}/${end.month}/${end.day}';
}
