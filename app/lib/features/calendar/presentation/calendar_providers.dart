import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/calendar/data/caching_personal_events_repository.dart';
import 'package:vrijdag/features/calendar/data/supabase_personal_events_repository.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_entry.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_scale.dart';
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

class MonthFeedWindow {
  const MonthFeedWindow({
    required this.from,
    required this.to,
    this.scale,
    this.slotCount = 1,
  });

  final DateTime from;
  final DateTime to;
  final FeedScale? scale;
  final int slotCount;

  MonthFeedWindow copyWith({
    DateTime? from,
    DateTime? to,
    FeedScale? scale,
    int? slotCount,
  }) {
    return MonthFeedWindow(
      from: from ?? this.from,
      to: to ?? this.to,
      scale: scale ?? this.scale,
      slotCount: slotCount ?? this.slotCount,
    );
  }
}

class MonthFeedWindowNotifier extends Notifier<MonthFeedWindow> {
  @override
  MonthFeedWindow build() {
    final anchor = ref.watch(calendarAnchorProvider);
    return MonthFeedWindow(
      from: DateTime(anchor.year, anchor.month - 1, 1),
      to: DateTime(anchor.year, anchor.month + 2, 1),
    );
  }

  void growTo(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    var from = state.from;
    var to = state.to;
    if (!date.isBefore(from) && date.isBefore(to)) {
      return;
    }
    if (date.isBefore(from)) {
      from = DateTime(date.year, date.month, 1);
    }
    if (!date.isBefore(to)) {
      to = DateTime(date.year, date.month + 1, 1);
    }
    state = state.copyWith(from: from, to: to);
  }

  void adoptScale(FeedScale next, {required int slots}) {
    final scale = state.scale == null ? next : state.scale!.expandTo(next);
    final slotCount = slots > state.slotCount ? slots : state.slotCount;
    final sameScale =
        state.scale != null &&
        state.scale!.startMinute == scale.startMinute &&
        state.scale!.endMinute == scale.endMinute;
    if (sameScale && slotCount == state.slotCount) {
      return;
    }
    state = state.copyWith(scale: scale, slotCount: slotCount);
  }
}

final monthFeedWindowProvider =
    NotifierProvider<MonthFeedWindowNotifier, MonthFeedWindow>(
      MonthFeedWindowNotifier.new,
    );

final monthFeedEventsProvider = FutureProvider.autoDispose<List<FeedEntry>>((
  ref,
) async {
  final from = ref.watch(monthFeedWindowProvider.select((w) => w.from));
  final to = ref.watch(monthFeedWindowProvider.select((w) => w.to));
  final masters = await ref
      .watch(personalEventsRepositoryProvider)
      .listOverlapping(from: from.toUtc(), to: to.toUtc());
  return projectFeedEntries(masters, from: from.toUtc(), to: to.toUtc());
});
