import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/data/personal_event_remote_row.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/reminder_schedule.dart';

void main() {
  final now = DateTime.utc(2026, 9, 24, 8);
  final anchor = DateTime.utc(2026, 9, 24, 10);

  PersonalEvent sample() {
    return PersonalEvent(
      id: '1',
      userId: 'u',
      title: 'Standup',
      timed: TimedEventSpan(
        startsAt: anchor,
        endsAt: anchor.add(const Duration(minutes: 30)),
        timezone: 'UTC',
      ),
      reminderMinutes: const [15, 60],
      guests: const ['Ada'],
      categoryId: 'werk',
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('two offsets both stay in the future', () {
    final times = reminderFireTimes(
      anchor: anchor,
      reminderMinutes: const [15, 60],
      now: now,
    );
    expect(times, [
      DateTime.utc(2026, 9, 24, 9, 45),
      DateTime.utc(2026, 9, 24, 9),
    ]);
    expect(
      reminderNotificationId('1', 15),
      isNot(reminderNotificationId('1', 60)),
    );
  });

  test('a past offset is dropped and an empty list clears', () {
    final times = reminderFireTimes(
      anchor: anchor,
      reminderMinutes: const [15, 180],
      now: DateTime.utc(2026, 9, 24, 9, 30),
    );
    expect(times, [DateTime.utc(2026, 9, 24, 9, 45)]);
    final cleared = sample().copyWith(
      reminderMinutes: const [],
      replaceReminders: true,
      guests: const [],
      replaceGuests: true,
    );
    expect(cleared.reminderMinutes, isEmpty);
    expect(cleared.guests, isEmpty);
    final kept = sample().copyWith(title: 'Later');
    expect(kept.reminderMinutes, [15, 60]);
    expect(kept.guests, ['Ada']);
  });

  test('removing one guest leaves the other', () {
    final event = sample().copyWith(
      guests: const ['Ada', 'Ben'],
      replaceGuests: true,
    );
    final next = [...event.guests]..remove('Ada');
    expect(next, ['Ben']);
  });

  test('remote row omits reminders guests and labels', () {
    final row = personalEventRemoteRow(sample());
    expect(row.keys, isNot(contains('guests')));
    expect(row.keys, isNot(contains('reminder_minutes')));
    expect(row.keys, isNot(contains('category_id')));
    expect(row['title'], 'Standup');
  });
}
