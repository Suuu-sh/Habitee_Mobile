import 'package:flutter/material.dart';
import '../models/habit_type.dart';
import '../services/storage_service.dart';
import 'character_screen.dart';
import 'category_select_screen.dart';
import 'collection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<HabitRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _storage.getRecords();
    setState(() {
      _records = records;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('habitee'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CollectionScreen()),
              );
              _loadRecords();
            },
            tooltip: 'コレクション',
          ),
        ],
      ),
      body: _records.isEmpty
          ? _buildEmptyState()
          : _buildRecordsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategorySelectScreen()),
          );
          _loadRecords();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'まだ記録がありません',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            '下のボタンから始めましょう',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Text(
              record.type.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            title: Text(record.type.displayName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${record.consecutiveDays}日連続 - ${record.stageLabel}'),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (record.consecutiveDays % 7) / 7,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CharacterScreen(record: record),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
