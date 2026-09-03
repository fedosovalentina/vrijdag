import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/database/app_database.dart';
import 'package:vrijdag/core/database/drift_write_queue.dart';
import 'package:vrijdag/core/database/write_queue.dart';
import 'package:vrijdag/core/database/write_queue_replayer.dart';
import 'package:vrijdag/features/calendar/data/drift_personal_events_cache.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final writeQueueProvider = Provider<WriteQueue>((ref) {
  return DriftWriteQueue(ref.watch(appDatabaseProvider));
});

final personalEventsCacheProvider = Provider<DriftPersonalEventsCache>((ref) {
  return DriftPersonalEventsCache(ref.watch(appDatabaseProvider));
});

/// Pending write-queue size for the offline banner.
final pendingWriteCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(writeQueueProvider).pendingCount();
});

/// Skeleton replayer — handler is a no-op until remote replay is wired.
final writeQueueReplayerProvider = Provider<WriteQueueReplayer>((ref) {
  return WriteQueueReplayer(
    queue: ref.watch(writeQueueProvider),
    handler: (_) async {
      // Intents are already applied optimistically against Supabase when online.
      // Offline-first replay of failed HTTP writes lands in a later F-009 slice.
    },
  );
});
