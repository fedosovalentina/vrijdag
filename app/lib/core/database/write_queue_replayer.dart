import 'package:vrijdag/core/database/write_queue.dart';

/// Applies a single offline intent against the server.
typedef SyncIntentHandler = Future<void> Function(SyncIntent intent);

/// Skeleton replay worker for F-009: peek → handle → remove / markAttempt.
///
/// Connectivity and backoff land in a later slice; callers decide when to run.
class WriteQueueReplayer {
  WriteQueueReplayer({
    required WriteQueue queue,
    required SyncIntentHandler handler,
  }) : _queue = queue,
       _handler = handler;

  final WriteQueue _queue;
  final SyncIntentHandler _handler;
  var _running = false;

  /// Processes up to [limit] intents in creation order.
  /// Returns how many intents were successfully removed from the queue.
  Future<int> replayOnce({int limit = 20}) async {
    if (_running) {
      return 0;
    }
    _running = true;
    var succeeded = 0;
    try {
      final intents = await _queue.peekOrdered(limit: limit);
      for (final intent in intents) {
        try {
          await _handler(intent);
          await _queue.remove(intent.id);
          succeeded++;
        } on Object catch (error) {
          await _queue.markAttempt(intent.id, lastError: error.toString());
          // Stop on first failure so later intents keep order.
          break;
        }
      }
    } finally {
      _running = false;
    }
    return succeeded;
  }
}
