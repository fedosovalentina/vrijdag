import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_expander.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_materializer.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_scope.dart';

void main() {
  test('this event adds one exclusion and detaches', () {
    final plan = planRecurrenceEdit(
      scope: RecurrenceScope.thisEvent,
      occurrence: DateTime(2026, 9, 15, 9),
      existingExdates: [DateTime(2026, 9, 8)],
      deleting: false,
    );

    expect(plan.detachOccurrence, isTrue);
    expect(plan.applyToSeries, isFalse);
    expect(plan.exdates, [DateTime(2026, 9, 8), DateTime(2026, 9, 15)]);
  });

  test('all keeps exclusions', () {
    final kept = [DateTime(2026, 9, 8)];
    final plan = planRecurrenceEdit(
      scope: RecurrenceScope.all,
      occurrence: DateTime(2026, 9, 15),
      existingExdates: kept,
      deleting: false,
    );

    expect(plan.exdates, kept);
    expect(plan.applyToSeries, isTrue);
    expect(plan.detachOccurrence, isFalse);
    expect(plan.replaceUntil, isFalse);
  });

  test('this and following ends the series the day before', () {
    final plan = planRecurrenceEdit(
      scope: RecurrenceScope.thisAndFollowing,
      occurrence: DateTime(2026, 9, 15, 18),
      existingExdates: const [],
      deleting: false,
    );

    expect(plan.seriesUntil, DateTime(2026, 9, 14));
    expect(plan.replaceUntil, isTrue);
    expect(plan.detachOccurrence, isTrue);
    expect(plan.applyToSeries, isFalse);
  });

  test('deleting this event does not create a replacement', () {
    final plan = planRecurrenceEdit(
      scope: RecurrenceScope.thisEvent,
      occurrence: DateTime(2026, 9, 15),
      existingExdates: const [],
      deleting: true,
    );

    expect(plan.detachOccurrence, isFalse);
    expect(plan.exdates, [DateTime(2026, 9, 15)]);
  });

  test('expander skips an excluded date and still counts it', () {
    const expander = RecurrenceExpander();
    final occurrences = expander.expand(
      rule: const RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        count: 3,
      ),
      seriesStart: DateTime.utc(2026, 9, 1, 9),
      from: DateTime.utc(2026, 9, 1),
      to: DateTime.utc(2026, 9, 10),
      exdates: [DateTime.utc(2026, 9, 2)],
    );

    expect(occurrences.map((item) => item.startsAt.day), [1, 3]);
  });

  test('materializer attaches the series and skips its exclusion', () {
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
        count: 3,
      ),
      recurrenceExdates: [DateTime.utc(2026, 9, 2)],
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      createdAt: now,
      updatedAt: now,
    );

    final out = RecurrenceMaterializer.materialize(
      [master],
      from: DateTime.utc(2026, 9, 1),
      to: DateTime.utc(2026, 9, 10),
    );

    expect(out.map((item) => item.timed!.startsAt.day), [1, 3]);
    expect(out.every((item) => identical(item.seriesMaster, master)), isTrue);
    expect(out.every((item) => !item.isRecurring), isTrue);
  });

  test('a series that started earlier still overlaps the window', () {
    final now = DateTime.utc(2026, 1, 1);
    final master = PersonalEvent(
      id: 'r1',
      userId: 'u',
      title: 'Standup',
      timed: TimedEventSpan(
        startsAt: DateTime.utc(2026, 1, 5, 9),
        endsAt: DateTime.utc(2026, 1, 5, 9, 30),
        timezone: 'UTC',
      ),
      recurrenceRule: const RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
      ),
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      createdAt: now,
      updatedAt: now,
    );

    expect(
      master.overlaps(DateTime.utc(2026, 9, 1), DateTime.utc(2026, 10, 1)),
      isTrue,
    );
  });
}
