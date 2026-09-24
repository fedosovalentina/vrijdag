import 'package:vrijdag/features/calendar/data/drift_personal_events_cache.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/personal_events_repository.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

/// Cache-first reads; writes go remote (local-first) then cache.
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
      final remote = await _remote.listOverlapping(from: from, to: to);
      await _cache.upsertAll(remote);
    } on Object {
      // Serve cache only.
    }

    final cached = await _cache.listForUser(_currentUserId());
    return cached
        .where((e) => !e.isDeleted)
        .where((e) => e.overlaps(from, to))
        .toList()
      ..sort(_compare);
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
    RecurrenceRule? recurrenceRule,
    DateTime? recurrenceUntil,
  }) async {
    final event = await _remote.createAllDay(
      title: title,
      startDate: startDate,
      endDate: endDate,
      timezone: timezone,
      notes: notes,
      location: location,
      recurrenceRule: recurrenceRule,
      recurrenceUntil: recurrenceUntil,
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
    final existing = await _findCached(eventId);
    if (existing != null) {
      await _cache.upsert(
        existing.copyWith(
          deletedAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    await _remote.softDelete(eventId);
  }

  @override
  Future<void> undoSoftDelete(String eventId) async {
    final existing = await _findCached(eventId);
    if (existing != null) {
      await _cache.upsert(
        existing.copyWith(
          clearDeletedAt: true,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    await _remote.undoSoftDelete(eventId);
  }

  Future<PersonalEvent?> _findCached(String eventId) async {
    final all = await _cache.listForUser(_currentUserId());
    for (final event in all) {
      if (event.id == eventId) {
        return event;
      }
    }
    return null;
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
