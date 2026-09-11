import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_materializer.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

void main() {
  test('materialize expands daily series into range', () {
    final now = DateTime.utc(2026, 9, 1);
    final master = PersonalEvent(
      id: 'r1',
      userId: 'u',
      title: 'Standup',
      timed: TimedEventSpan(
        startsAt: DateTime.utc(2026, 9, 1, 9),
        endsAt: DateTime.utc(2026, 9, 1, 9, 30),
        timezone: 'UTC',
      ),
      recurrenceRule: const RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
      ),
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      createdAt: now,
      updatedAt: now,
    );

    final out = RecurrenceMaterializer.materialize(
      [master],
      from: DateTime.utc(2026, 9, 1),
      to: DateTime.utc(2026, 9, 4),
    );

    expect(out, hasLength(3));
    expect(out.every((e) => !e.isRecurring), isTrue);
    expect(out.first.timed!.startsAt.day, 1);
    expect(out.last.timed!.startsAt.day, 3);
  });
}
