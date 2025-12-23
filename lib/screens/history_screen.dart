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
    return Container(
      color: const Color(0xFFF4F1FA),
      child: _entries.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 52, 20, 10),
                  child: _FilterBar(
                    taskLabel: _selectedTask ?? 'すべて',
                    rangeLabel: _formatRange(_rangeStart, _rangeEnd),
                    onTap: _openFilterSheet,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: visibleEntries.length,
                    itemBuilder: (context, index) {
                      final entry = visibleEntries[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9E9EF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Color(entry.color),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.taskName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDate(entry.date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              entry.comment,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
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

Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🗂️', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(
          '失敗の記録はまだありません',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9E9EF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$taskLabel / $rangeLabel',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18),
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

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'フィルター',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  const Text('タスク'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: tempTask,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
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
                  const SizedBox(height: 16),
                  const Text('期間'),
                  const SizedBox(height: 8),
                  OutlinedButton(
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
                    child: Text(_formatRange(tempStart, tempEnd)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempTask = null;
                            tempStart = null;
                            tempEnd = null;
                          });
                        },
                        child: const Text('クリア'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('適用'),
                      ),
                    ],
                  ),
                ],
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
