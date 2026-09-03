import 'package:vrijdag/features/calendar/data/drift_personal_events_cache.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/personal_events_repository.dart';

/// Prefers the remote repository; falls back to Drift on read failure.
class CachingPersonalEventsRepository implements PersonalEventsRepository {
  CachingPersonalEventsRepository({
    required PersonalEventsRepository remote,
    required DriftPersonalEventsCache cache,
    required String Function() currentUserId,
  }) : _remote = remote,
       _cache = cache,
       _currentUserId = currentUserId;

  final PersonalEventsRepository _remote;
  final DriftPersonalEventsCache _cache;
  final String Function() _currentUserId;

  @override
  Future<List<PersonalEvent>> listOverlapping({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final events = await _remote.listOverlapping(from: from, to: to);
      await _cache.upsertAll(events);
      return events;
    } on Object {
      final cached = await _cache.listForUser(_currentUserId());
      return cached
          .where((e) => !e.isDeleted)
          .where((e) => _overlaps(e, from, to))
          .toList()
        ..sort(_compare);
    }
  }

  @override
  Future<PersonalEvent> createTimed(NewTimedEventDraft draft) async {
    final event = await _remote.createTimed(draft);
    await _cache.upsert(event);
    return event;
  }

  @override
  Future<PersonalEvent> createAllDay({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String timezone,
    String? notes,
    String? location,
  }) async {
    final event = await _remote.createAllDay(
      title: title,
      startDate: startDate,
      endDate: endDate,
      timezone: timezone,
      notes: notes,
      location: location,
    );
    await _cache.upsert(event);
    return event;
  }

  @override
  Future<PersonalEvent> update(PersonalEvent event) async {
    final updated = await _remote.update(event);
    await _cache.upsert(updated);
    return updated;
  }

  @override
  Future<void> softDelete(String eventId) async {
    await _remote.softDelete(eventId);
    await _cache.remove(eventId);
  }

  @override
  Future<void> undoSoftDelete(String eventId) async {
    await _remote.undoSoftDelete(eventId);
    // Next list refresh will rehydrate the cache.
  }

  bool _overlaps(PersonalEvent event, DateTime from, DateTime to) {
    if (event.timed != null) {
      return event.timed!.startsAt.isBefore(to) &&
          event.timed!.endsAt.isAfter(from);
    }
    final span = event.allDay!;
    final start = DateTime.utc(
      span.startDate.year,
      span.startDate.month,
      span.startDate.day,
    );
    final endExclusive = DateTime.utc(
      span.endDate.year,
      span.endDate.month,
      span.endDate.day,
    ).add(const Duration(days: 1));
    return start.isBefore(to) && endExclusive.isAfter(from);
  }

  int _compare(PersonalEvent a, PersonalEvent b) {
    final aStart =
        a.timed?.startsAt ??
        DateTime.utc(
          a.allDay!.startDate.year,
          a.allDay!.startDate.month,
          a.allDay!.startDate.day,
        );
    final bStart =
        b.timed?.startsAt ??
        DateTime.utc(
          b.allDay!.startDate.year,
          b.allDay!.startDate.month,
          b.allDay!.startDate.day,
        );
    return aStart.compareTo(bStart);
  }
}
