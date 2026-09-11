import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/shared/widgets/hour_spine.dart';

void main() {
  PersonalEvent timedAt(DateTime start) {
    final now = DateTime.utc(2026, 9, 11);
    return PersonalEvent(
      id: 'e-${start.hour}',
      userId: 'u',
      title: 'At ${start.hour}',
      timed: TimedEventSpan(
        startsAt: start,
        endsAt: start.add(const Duration(minutes: 30)),
        timezone: 'UTC',
      ),
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('busyRows inserts sparse empty hours around timed events', () {
    final events = [
      timedAt(DateTime(2026, 9, 11, 10)),
      timedAt(DateTime(2026, 9, 11, 15)),
    ];

    final rows = HourSpine.busyRows(
      timed: events,
      timeLabel: (_) => 'x',
      subtitle: (_) => null,
      onEventTap: (_) {},
    );

    // Anchors 8, 12, 18 plus two events.
    expect(rows, hasLength(5));
  });

  test('busyRows omits anchors that already have an event hour', () {
    final events = [
      timedAt(DateTime(2026, 9, 11, 8)),
      timedAt(DateTime(2026, 9, 11, 12)),
    ];

    final rows = HourSpine.busyRows(
      timed: events,
      timeLabel: (_) => 'x',
      subtitle: (_) => null,
      onEventTap: (_) {},
    );

    // Events at 8 and 12; only empty 18 remains.
    expect(rows, hasLength(3));
  });
}
