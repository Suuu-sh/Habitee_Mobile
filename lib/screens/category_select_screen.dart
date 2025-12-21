import 'package:flutter/material.dart';
import '../models/habit_type.dart';
import '../services/storage_service.dart';

class CategorySelectScreen extends StatelessWidget {
  const CategorySelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カテゴリー選択'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: HabitType.values.length,
        itemBuilder: (context, index) {
          final type = HabitType.values[index];
          return _CategoryCard(
            type: type,
            onTap: () async {
              await StorageService().addRecord(type);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final HabitType type;
  final VoidCallback onTap;

  const _CategoryCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
