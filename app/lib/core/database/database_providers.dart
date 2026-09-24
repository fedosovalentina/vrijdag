import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/database/app_database.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/core/database/drift_write_queue.dart';
import 'package:vrijdag/core/database/sync_intent_applier.dart';
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

/// True when the oldest queued change has failed often enough to wait
/// for an explicit retry.
final stuckWriteProvider = FutureProvider.autoDispose<bool>((ref) async {
  final head = await ref.watch(writeQueueProvider).peekOrdered(limit: 1);
  if (head.isEmpty) {
    return false;
  }
  return head.first.attempts >= syncGiveUpAttempts;
});

final syncIntentApplierProvider = Provider<SyncIntentApplier>((ref) {
  return SyncIntentApplier();
});

final writeQueueReplayerProvider = Provider<WriteQueueReplayer>((ref) {
  final applier = ref.watch(syncIntentApplierProvider);
  return WriteQueueReplayer(
    queue: ref.watch(writeQueueProvider),
    handler: applier.apply,
  );
});

/// True when the device reports any non-none connectivity.
final isOnlineProvider = StreamProvider.autoDispose<bool>((ref) async* {
  try {
    final connectivity = Connectivity();
    yield _hasLink(await connectivity.checkConnectivity());
    await for (final results in connectivity.onConnectivityChanged) {
      yield _hasLink(results);
    }
  } on Object {
    // Tests / missing plugins must not break the home shell.
    yield true;
  }
});

/// Newest personal-event cache time for the signed-in user.
final cacheFreshnessProvider = FutureProvider.autoDispose<DateTime?>((
  ref,
) async {
  final id = supabaseClient?.auth.currentUser?.id;
  if (id == null) {
    return null;
  }
  return ref.watch(personalEventsCacheProvider).latestCachedAt(id);
});

bool _hasLink(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}

/// Replays the write queue whenever connectivity returns.
final writeQueueReplayControllerProvider = Provider<void>((ref) {
  final replayer = ref.watch(writeQueueReplayerProvider);
  ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) async {
    final wasOffline = previous?.valueOrNull == false;
    final online = next.valueOrNull == true;
    if (online && (wasOffline || previous == null)) {
      final flushed = await replayer.replayOnce();
      if (flushed > 0) {
        await ref
            .read(analyticsProvider)
            .track(SyncQueueFlushed(count: flushed));
      }
      final head = await ref.read(writeQueueProvider).peekOrdered(limit: 1);
      if (head.isNotEmpty && head.first.attempts >= syncGiveUpAttempts) {
        await ref
            .read(analyticsProvider)
            .track(const SyncFailed(reason: 'stuck'));
      }
      ref.invalidate(pendingWriteCountProvider);
      ref.invalidate(stuckWriteProvider);
    }
  });
});
