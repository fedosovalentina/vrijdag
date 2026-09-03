import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/personal_events_repository.dart';

class MemoryPersonalEventsRepository implements PersonalEventsRepository {
  final _events = <String, PersonalEvent>{};

  @override
  Future<List<PersonalEvent>> listOverlapping({
    required DateTime from,
    required DateTime to,
  }) async {
    return _events.values.where((e) => !e.isDeleted).where((e) {
      if (e.timed != null) {
        return e.timed!.startsAt.isBefore(to) && e.timed!.endsAt.isAfter(from);
      }
      return true;
    }).toList();
  }

  @override
  Future<PersonalEvent> createTimed(NewTimedEventDraft draft) async {
    final now = DateTime.now().toUtc();
    final event = PersonalEvent(
      id: 'mem-${_events.length + 1}',
      userId: 'user',
      title: draft.title,
      notes: draft.notes,
      location: draft.location,
      timed: TimedEventSpan(
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        timezone: draft.timezone,
      ),
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      createdAt: now,
      updatedAt: now,
    );
    _events[event.id] = event;
    return event;
  }

  @override
  Future<PersonalEvent> createAllDay({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? location,
  }) async {
    final now = DateTime.now().toUtc();
    final event = PersonalEvent(
      id: 'mem-${_events.length + 1}',
      userId: 'user',
      title: title,
      notes: notes,
      location: location,
      allDay: AllDayEventSpan(startDate: startDate, endDate: endDate),
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      createdAt: now,
      updatedAt: now,
    );
    _events[event.id] = event;
    return event;
  }

  @override
  Future<PersonalEvent> update(PersonalEvent event) async {
    _events[event.id] = event;
    return event;
  }

  @override
  Future<void> softDelete(String eventId) async {
    final existing = _events[eventId];
    if (existing == null) {
      return;
    }
    _events[eventId] = PersonalEvent(
      id: existing.id,
      userId: existing.userId,
      title: existing.title,
      notes: existing.notes,
      location: existing.location,
      timed: existing.timed,
      allDay: existing.allDay,
      source: existing.source,
      sourceOfTruth: existing.sourceOfTruth,
      deletedAt: DateTime.now().toUtc(),
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> undoSoftDelete(String eventId) async {
    final existing = _events[eventId];
    if (existing == null) {
      return;
    }
    _events[eventId] = PersonalEvent(
      id: existing.id,
      userId: existing.userId,
      title: existing.title,
      notes: existing.notes,
      location: existing.location,
      timed: existing.timed,
      allDay: existing.allDay,
      source: existing.source,
      sourceOfTruth: existing.sourceOfTruth,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
