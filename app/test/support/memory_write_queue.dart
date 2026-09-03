import 'package:vrijdag/core/database/write_queue.dart';

class MemoryWriteQueue implements WriteQueue {
  final _items = <SyncIntent>[];

  @override
  Future<void> enqueue(SyncIntent intent) async {
    _items.removeWhere((item) => item.id == intent.id);
    _items.add(intent);
    _items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<int> pendingCount() async => _items.length;

  @override
  Future<List<SyncIntent>> peekOrdered({int limit = 50}) async {
    return _items.take(limit).toList(growable: false);
  }
}
