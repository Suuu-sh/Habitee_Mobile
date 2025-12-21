import 'package:flutter/material.dart';
import '../models/habit_type.dart';
import '../services/storage_service.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final StorageService _storage = StorageService();
  List<CollectedCharacter> _collection = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _storage.getCollection();
    items.sort((a, b) => b.collectedAt.compareTo(a.collectedAt));
    setState(() {
      _collection = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('コレクション'),
      ),
      body: _collection.isEmpty
          ? const Center(child: Text('まだコレクションはありません'))
          : ListView.builder(
              itemCount: _collection.length,
              itemBuilder: (context, index) {
                final item = _collection[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      item.type.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(item.characterKind.displayName),
                  subtitle: Text(
                    'クリア済み: ${_stageLabel(item.stageIndex)}・${item.type.displayName}',
                  ),
                  trailing: Text(
                    _formatDate(item.collectedAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                );
              },
            ),
    );
  }
}

String _stageLabel(int stage) {
  switch (stage) {
    case 0:
      return '週1';
    case 1:
      return '週2';
    case 2:
      return '週3';
    case 3:
      return '週4';
    default:
      return '週1';
  }
}

String _formatDate(DateTime date) {
  return '${date.year}/${date.month}/${date.day}';
}
