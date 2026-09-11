import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';

/// Presence helpers for Week / Month / Year Layer 1 markers.
abstract final class CalendarPresence {
  static bool eventOverlapsDay(PersonalEvent event, DateTime day) {
    final startOfDay = CalendarRange.dateOnly(day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    if (event.isAllDay) {
      final span = event.allDay!;
      final start = CalendarRange.dateOnly(span.startDate);
      final endExclusive = CalendarRange.dateOnly(
        span.endDate,
      ).add(const Duration(days: 1));
      return start.isBefore(endOfDay) && endExclusive.isAfter(startOfDay);
    }

    final start = event.timed!.startsAt.toLocal();
    final end = event.timed!.endsAt.toLocal();
    return end.isAfter(startOfDay) && start.isBefore(endOfDay);
  }

  static bool birthdayOnDay(Birthday birthday, DateTime day) {
    final occ = Birthday.occurrenceDate(
      year: day.year,
      month: birthday.month,
      day: birthday.day,
    );
    return occ.month == day.month && occ.day == day.day;
  }

  static List<PersonalEvent> eventsOnDay(
    List<PersonalEvent> events,
    DateTime day,
  ) {
    return events.where((e) => eventOverlapsDay(e, day)).toList();
  }

  static List<Birthday> birthdaysOnDay(List<Birthday> birthdays, DateTime day) {
    return birthdays.where((b) => birthdayOnDay(b, day)).toList();
  }

  static bool dayHasEvent(List<PersonalEvent> events, DateTime day) =>
      events.any((e) => eventOverlapsDay(e, day));

  static bool dayHasBirthday(List<Birthday> birthdays, DateTime day) =>
      birthdays.any((b) => birthdayOnDay(b, day));
}
