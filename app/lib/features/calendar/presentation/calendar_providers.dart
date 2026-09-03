import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/features/calendar/data/supabase_personal_events_repository.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/personal_events_repository.dart';

final personalEventsRepositoryProvider = Provider<PersonalEventsRepository>((
  ref,
) {
  return SupabasePersonalEventsRepository(
    writeQueue: ref.watch(writeQueueProvider),
  );
});

/// Events overlapping "today" in the device local calendar day.
final todaysEventsProvider = FutureProvider.autoDispose<List<PersonalEvent>>((
  ref,
) async {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day).toUtc();
  final to = from.add(const Duration(days: 1));
  return ref
      .watch(personalEventsRepositoryProvider)
      .listOverlapping(from: from, to: to);
});
