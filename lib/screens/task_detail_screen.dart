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

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'タスクを削除',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: const Text(
            'この操作は取り消せません。\n本当に削除しますか？',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) return;
    await _storage.deleteRecord(widget.record.id);
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Color(_selectedColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _controller.text.trim().isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('タスク詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
            color: Colors.red,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(_selectedColor).withOpacity(0.1),
                  Color(_selectedColor).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color(_selectedColor).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: TaskHistoryGrid(record: widget.record),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            icon: Icons.calendar_today_rounded,
            iconColor: colorScheme.primary,
            title: '開始日',
            child: InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      color: Color(_selectedColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_startDate.year}年${_startDate.month}月${_startDate.day}日',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            icon: Icons.label_rounded,
            iconColor: colorScheme.secondary,
            title: 'タスク名',
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '例: ランニング',
                prefixIcon: Icon(Icons.edit_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            icon: Icons.note_rounded,
            iconColor: Colors.orange,
            title: 'メモ',
            child: TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                hintText: '自由にメモを書いてください',
                prefixIcon: Icon(Icons.description_rounded),
              ),
              minLines: 3,
              maxLines: 6,
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            icon: Icons.palette_rounded,
            iconColor: Colors.pink,
            title: 'カラーテーマ',
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: taskColors.map((color) {
                  final isSelected = _selectedColor == color.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(isSelected ? 0.5 : 0.2),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded),
                SizedBox(width: 8),
                Text(
                  '保存',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
