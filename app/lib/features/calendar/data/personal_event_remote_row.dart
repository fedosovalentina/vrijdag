import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

/// Columns that exist on `app.personal_events` today.
///
/// Reminders, guests, and labels stay on the device. Sending them would
/// fail the update for the current account.
Map<String, dynamic> personalEventRemoteRow(PersonalEvent event) {
  return {
    'title': event.title.trim(),
    'notes': event.notes,
    'location': event.location,
    'starts_at': event.timed?.startsAt.toUtc().toIso8601String(),
    'ends_at': event.timed?.endsAt.toUtc().toIso8601String(),
    'start_date': event.allDay == null
        ? null
        : _dateOnly(event.allDay!.startDate),
    'end_date': event.allDay == null ? null : _dateOnly(event.allDay!.endDate),
    'timezone':
        event.timed?.timezone ??
        (event.allDay != null ? 'Europe/Amsterdam' : 'UTC'),
    'all_day': event.isAllDay,
    'recurrence_rule': encodeStoredRecurrence(
      event.recurrenceRule,
      event.recurrenceExdates,
    ),
    'recurrence_until': event.recurrenceUntil == null
        ? null
        : _dateOnly(event.recurrenceUntil!),
    'deleted_at': event.deletedAt?.toUtc().toIso8601String(),
    'updated_at': event.updatedAt.toUtc().toIso8601String(),
  };
}

String _dateOnly(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
