import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/calendar/domain/calendar_presence.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';

void main() {
  group('CalendarRange', () {
    test('startOfWeek is Monday', () {
      final wednesday = DateTime(2026, 9, 2);
      expect(CalendarRange.startOfWeek(wednesday), DateTime(2026, 8, 31));
    });

    test('visibleRange for week is seven days', () {
      final (from, to) = CalendarRange.visibleRange(
        CalendarScale.week,
        DateTime(2026, 9, 3),
      );
      expect(from, DateTime(2026, 8, 31));
      expect(to, DateTime(2026, 9, 7));
    });

    test('seasonMonths for September is autumn', () {
      expect(CalendarRange.seasonMonths(9), [9, 10, 11]);
    });

    test('isoWeeksInMonth returns weeks overlapping September 2026', () {
      final weeks = CalendarRange.isoWeeksInMonth(2026, 9);
      expect(weeks, isNotEmpty);
      expect(weeks, contains(36));
    });
  });

  group('CalendarPresence', () {
    final now = DateTime(2026, 9, 3, 12);

    PersonalEvent timed({required DateTime start, Duration? duration}) {
      return PersonalEvent(
        id: 'e1',
        userId: 'u',
        title: 'x',
        timed: TimedEventSpan(
          startsAt: start.toUtc(),
          endsAt: start.add(duration ?? const Duration(hours: 1)).toUtc(),
          timezone: 'UTC',
        ),
        source: EventSource.vrijdag,
        sourceOfTruth: SourceOfTruth.vrijdag,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('timed event overlaps local day', () {
      final event = timed(start: DateTime(2026, 9, 3, 9));
      expect(
        CalendarPresence.eventOverlapsDay(event, DateTime(2026, 9, 3)),
        isTrue,
      );
      expect(
        CalendarPresence.eventOverlapsDay(event, DateTime(2026, 9, 4)),
        isFalse,
      );
    });

    test('birthday respects Feb 29 rule', () {
      final birthday = Birthday(
        id: 'b',
        userId: 'u',
        name: 'Ada',
        month: 2,
        day: 29,
        createdAt: now,
        updatedAt: now,
      );
      expect(
        CalendarPresence.birthdayOnDay(birthday, DateTime(2025, 2, 28)),
        isTrue,
      );
      expect(
        CalendarPresence.birthdayOnDay(birthday, DateTime(2025, 2, 27)),
        isFalse,
      );
    });
  });
}
