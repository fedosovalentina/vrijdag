import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';

void main() {
  test('default timed duration is 60 minutes', () {
    final start = DateTime.utc(2026, 9, 3, 10);
    expect(defaultTimedEventEnd(start), DateTime.utc(2026, 9, 3, 11));
    expect(defaultTimedEventDuration, const Duration(minutes: 60));
  });

  test('rejects end before start for timed and all-day', () {
    expect(
      () => TimedEventSpan(
        startsAt: DateTime.utc(2026, 9, 3, 12),
        endsAt: DateTime.utc(2026, 9, 3, 11),
        timezone: 'Europe/Amsterdam',
      ).validate(),
      throwsArgumentError,
    );
    expect(
      () => AllDayEventSpan(
        startDate: DateTime(2026, 9, 4),
        endDate: DateTime(2026, 9, 3),
      ).validate(),
      throwsArgumentError,
    );
  });

  test('NewTimedEventDraft applies 60 minute default', () {
    final draft = NewTimedEventDraft(
      title: 'Lunch',
      startsAt: DateTime.utc(2026, 9, 3, 12),
      timezone: 'Europe/Amsterdam',
    );
    expect(draft.endsAt, DateTime.utc(2026, 9, 3, 13));
  });
}
