import 'package:vrijdag/features/calendar/domain/personal_event.dart';

abstract class PersonalEventsRepository {
  /// Active (non-deleted) events overlapping [from, to) in UTC.
  Future<List<PersonalEvent>> listOverlapping({
    required DateTime from,
    required DateTime to,
  });

  Future<PersonalEvent> createTimed(NewTimedEventDraft draft);

  Future<PersonalEvent> createAllDay({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String timezone,
    String? notes,
    String? location,
  });

  Future<PersonalEvent> update(PersonalEvent event);

  /// Soft-delete (sets deleted_at). Caller may undo within the UI window.
  Future<void> softDelete(String eventId);

  Future<void> undoSoftDelete(String eventId);
}
