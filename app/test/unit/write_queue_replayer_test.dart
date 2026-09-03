import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/core/database/write_queue.dart';
import 'package:vrijdag/core/database/write_queue_replayer.dart';

import '../support/memory_write_queue.dart';

void main() {
  test('replayer removes successful intents and stops on failure', () async {
    final queue = MemoryWriteQueue();
    await queue.enqueue(
      SyncIntent(
        id: 'a',
        type: 'ok',
        payloadJson: '{}',
        createdAt: DateTime.utc(2026, 9, 3, 10),
      ),
    );
    await queue.enqueue(
      SyncIntent(
        id: 'b',
        type: 'fail',
        payloadJson: '{}',
        createdAt: DateTime.utc(2026, 9, 3, 11),
      ),
    );
    await queue.enqueue(
      SyncIntent(
        id: 'c',
        type: 'ok',
        payloadJson: '{}',
        createdAt: DateTime.utc(2026, 9, 3, 12),
      ),
    );

    final replayer = WriteQueueReplayer(
      queue: queue,
      handler: (intent) async {
        if (intent.type == 'fail') {
          throw StateError('boom');
        }
      },
    );

    final done = await replayer.replayOnce();
    expect(done, 1);
    expect(await queue.pendingCount(), 2);
    final remaining = await queue.peekOrdered();
    expect(remaining.first.id, 'b');
    expect(remaining.first.attempts, 1);
  });
}
