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

  @override
  Future<void> markAttempt(String id, {required String? lastError}) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }
    final current = _items[index];
    _items[index] = SyncIntent(
      id: current.id,
      type: current.type,
      payloadJson: current.payloadJson,
      createdAt: current.createdAt,
      attempts: current.attempts + 1,
      lastError: lastError,
    );
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}
