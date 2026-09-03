/// A durable offline change waiting to be replayed to the server.
class SyncIntent {
  const SyncIntent({
    required this.id,
    required this.type,
    required this.payloadJson,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  final String id;
  final String type;
  final String payloadJson;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
}

abstract class WriteQueue {
  Future<void> enqueue(SyncIntent intent);

  Future<int> pendingCount();

  Future<List<SyncIntent>> peekOrdered({int limit = 50});

  Future<void> markAttempt(String id, {required String? lastError});

  Future<void> remove(String id);
}
