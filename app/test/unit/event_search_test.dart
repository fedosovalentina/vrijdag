import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/event_search.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

void main() {
  PersonalEvent event({
    required String id,
    required String title,
    String? notes,
    String? location,
    DateTime? start,
    RecurrenceRule? rule,
  }) {
    final at = start ?? DateTime.utc(2024, 1, 2, 9);
    return PersonalEvent(
      id: id,
      userId: 'u',
      title: title,
      notes: notes,
      location: location,
      timed: TimedEventSpan(
        startsAt: at,
        endsAt: at.add(const Duration(hours: 1)),
        timezone: 'UTC',
      ),
      recurrenceRule: rule,
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      createdAt: at,
      updatedAt: at,
    );
  }

  test('empty query returns nothing', () {
    final found = searchPersonalEvents(
      masters: [event(id: '1', title: 'Tandarts')],
      query: '   ',
      now: DateTime.utc(2026, 9, 1),
    );
    expect(found, isEmpty);
  });

  test('notes match and location does not', () {
    final masters = [
      event(id: '1', title: 'Afspraak', notes: 'kaarten meenemen'),
      event(id: '2', title: 'Afspraak', location: 'kaarten'),
    ];
    final found = searchPersonalEvents(
      masters: masters,
      query: 'kaarten',
      now: DateTime.utc(2026, 9, 1),
    );
    expect(found.map((item) => item.id), ['1']);
  });

  test('a repeating event is the next occurrence, once', () {
    final found = searchPersonalEvents(
      masters: [
        event(
          id: 'series',
          title: 'Standup',
          start: DateTime.utc(2026, 1, 5, 9),
          rule: const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
        ),
      ],
      query: 'stand',
      now: DateTime.utc(2026, 9, 24, 12),
    );
    expect(found, hasLength(1));
    expect(found.single.seriesMaster?.id, 'series');
    expect(found.single.timed!.startsAt.isAfter(DateTime.utc(2026, 9, 24)), isTrue);
  });
}
