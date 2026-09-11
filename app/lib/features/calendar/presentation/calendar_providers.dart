import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/calendar/data/caching_personal_events_repository.dart';
import 'package:vrijdag/features/calendar/data/supabase_personal_events_repository.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/personal_events_repository.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_materializer.dart';

final personalEventsRepositoryProvider = Provider<PersonalEventsRepository>((
  ref,
) {
  final remote = SupabasePersonalEventsRepository(
    writeQueue: ref.watch(writeQueueProvider),
  );
  return CachingPersonalEventsRepository(
    remote: remote,
    cache: ref.watch(personalEventsCacheProvider),
    currentUserId: () {
      final id = supabaseClient?.auth.currentUser?.id;
      if (id == null) {
        throw StateError('Not signed in');
      }
      return id;
    },
  );
});

final calendarAnchorProvider = StateProvider<DateTime>((ref) {
  return CalendarRange.dateOnly(DateTime.now());
});

final calendarScaleProvider = StateProvider<CalendarScale>(
  (ref) => CalendarScale.day,
);

/// Events overlapping the visible range of the current scale + anchor.
final visibleEventsProvider = FutureProvider.autoDispose<List<PersonalEvent>>((
  ref,
) async {
  final scale = ref.watch(calendarScaleProvider);
  final anchor = ref.watch(calendarAnchorProvider);
  final (from, to) = CalendarRange.visibleRange(scale, anchor);
  final masters = await ref
      .watch(personalEventsRepositoryProvider)
      .listOverlapping(from: from.toUtc(), to: to.toUtc());
  return RecurrenceMaterializer.materialize(
    masters,
    from: from.toUtc(),
    to: to.toUtc(),
  );
});

/// Events overlapping "today" in the device local calendar day.
final todaysEventsProvider = FutureProvider.autoDispose<List<PersonalEvent>>((
  ref,
) async {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day).toUtc();
  final to = from.add(const Duration(days: 1));
  final masters = await ref
      .watch(personalEventsRepositoryProvider)
      .listOverlapping(from: from, to: to);
  return RecurrenceMaterializer.materialize(masters, from: from, to: to);
});

/// Events for the Day anchor (local calendar day).
final dayEventsProvider = FutureProvider.autoDispose<List<PersonalEvent>>((
  ref,
) async {
  final anchor = ref.watch(calendarAnchorProvider);
  final day = CalendarRange.dateOnly(anchor);
  final from = day.toUtc();
  final to = day.add(const Duration(days: 1)).toUtc();
  final masters = await ref
      .watch(personalEventsRepositoryProvider)
      .listOverlapping(from: from, to: to);
  return RecurrenceMaterializer.materialize(masters, from: from, to: to);
});
