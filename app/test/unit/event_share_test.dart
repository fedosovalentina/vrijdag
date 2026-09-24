import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/event_share.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

void main() {
  test('text has the title and time and no link', () {
    final now = DateTime.utc(2026, 9, 24, 9);
    final event = PersonalEvent(
      id: '1',
      userId: 'u',
      title: 'Standup',
      notes: 'private',
      timed: TimedEventSpan(
        startsAt: now,
        endsAt: now.add(const Duration(minutes: 30)),
        timezone: 'UTC',
      ),
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      createdAt: now,
      updatedAt: now,
    );
    final text = eventShareText(event, allDayLabel: 'Hele dag', untitled: 'Zonder titel');
    expect(text, contains('Standup'));
    expect(text, isNot(contains('private')));
    expect(text, isNot(contains('http')));
  });

  test('a weekly event ics contains the rule and no url', () {
    final now = DateTime.utc(2026, 9, 24, 9);
    final master = PersonalEvent(
      id: 'series',
      userId: 'u',
      title: 'Standup',
      timed: TimedEventSpan(
        startsAt: now,
        endsAt: now.add(const Duration(minutes: 30)),
        timezone: 'UTC',
      ),
      recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      createdAt: now,
      updatedAt: now,
    );
    final ics = eventToIcs(master);
    expect(ics, contains('RRULE:FREQ=WEEKLY'));
    expect(ics.toLowerCase(), isNot(contains('http')));
    expect(ics, isNot(contains('URL:')));
  });
}
