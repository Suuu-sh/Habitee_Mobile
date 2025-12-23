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

  @override
  void initState() {
    super.initState();
    _load();
    widget.refreshListenable?.addListener(_load);
  }

  Future<void> _load() async {
    final records = await _storage.getRecords();
    final entries = <_FailureEntry>[];
    for (final record in records) {
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
    });
  }

  @override
  void dispose() {
    widget.refreshListenable?.removeListener(_load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F1FA),
      child: _entries.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
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
