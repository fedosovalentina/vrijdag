import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/core/database/app_database.dart';
import 'package:vrijdag/core/database/drift_write_queue.dart';
import 'package:vrijdag/core/database/write_queue.dart';

void main() {
  late AppDatabase db;
  late DriftWriteQueue queue;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = DriftWriteQueue(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('write queue persists order and count', () async {
    await queue.enqueue(
      SyncIntent(
        id: '2',
        type: 'event.create',
        payloadJson: '{}',
        createdAt: DateTime.utc(2026, 9, 3, 12),
      ),
    );
    await queue.enqueue(
      SyncIntent(
        id: '1',
        type: 'event.create',
        payloadJson: '{}',
        createdAt: DateTime.utc(2026, 9, 3, 11),
      ),
    );

    expect(await queue.pendingCount(), 2);
    final ordered = await queue.peekOrdered();
    expect(ordered.map((e) => e.id), ['1', '2']);
  });
}
