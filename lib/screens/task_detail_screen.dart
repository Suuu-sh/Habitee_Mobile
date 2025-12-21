import 'package:flutter/material.dart';
import '../models/habit_type.dart';
import '../services/storage_service.dart';
import '../widgets/task_colors.dart';
import '../widgets/task_history_grid.dart';

class TaskDetailScreen extends StatefulWidget {
  final HabitRecord record;

  const TaskDetailScreen({super.key, required this.record});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final StorageService _storage = StorageService();
  late TextEditingController _controller;
  late TextEditingController _memoController;
  late int _selectedColor;
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.record.type);
    _memoController = TextEditingController(text: widget.record.memo);
    _selectedColor = widget.record.color;
    _startDate = widget.record.startDate;
  }

  @override
  void dispose() {
    _controller.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await _storage.updateRecord(
      widget.record.id,
      type: name,
      color: _selectedColor,
      memo: _memoController.text.trim(),
      startDate: _startDate,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _controller.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('タスク'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TaskHistoryGrid(record: widget.record),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '開始日',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickStartDate,
            child: Text(
              '${_startDate.year}/${_startDate.month}/${_startDate.day}',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'タスク名',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: '例: ランニング',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'メモ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _memoController,
            decoration: const InputDecoration(
              hintText: '自由にメモを書いてください',
              border: OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: 16),
          const Text(
            '色',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: taskColors.map((color) {
              final isSelected = _selectedColor == color.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color.value),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: canSave ? _save : null,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
