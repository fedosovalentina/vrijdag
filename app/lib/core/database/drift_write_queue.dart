import 'package:drift/drift.dart';
import 'package:vrijdag/core/database/app_database.dart';
import 'package:vrijdag/core/database/write_queue.dart';

class DriftWriteQueue implements WriteQueue {
  DriftWriteQueue(this._db);

  final AppDatabase _db;

  @override
  Future<void> enqueue(SyncIntent intent) {
    return _db
        .into(_db.writeQueueEntries)
        .insert(
          WriteQueueEntriesCompanion.insert(
            id: intent.id,
            intentType: intent.type,
            payloadJson: intent.payloadJson,
            createdAt: intent.createdAt,
            attempts: Value(intent.attempts),
            lastError: Value(intent.lastError),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<int> pendingCount() async {
    final count = _db.writeQueueEntries.id.count();
    final query = _db.selectOnly(_db.writeQueueEntries)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<List<SyncIntent>> peekOrdered({int limit = 50}) async {
    final rows =
        await (_db.select(_db.writeQueueEntries)
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
              ..limit(limit))
            .get();

    return [
      for (final row in rows)
        SyncIntent(
          id: row.id,
          type: row.intentType,
          payloadJson: row.payloadJson,
          createdAt: row.createdAt,
          attempts: row.attempts,
          lastError: row.lastError,
        ),
    ];
  }

  @override
  Future<void> markAttempt(String id, {required String? lastError}) async {
    final existing = await (_db.select(
      _db.writeQueueEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      return;
    }
    await (_db.update(
      _db.writeQueueEntries,
    )..where((t) => t.id.equals(id))).write(
      WriteQueueEntriesCompanion(
        attempts: Value(existing.attempts + 1),
        lastError: Value(lastError),
      ),
    );
  }

  @override
  Future<void> remove(String id) {
    return (_db.delete(
      _db.writeQueueEntries,
    )..where((t) => t.id.equals(id))).go();
  }
}
