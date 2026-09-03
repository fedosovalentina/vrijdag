import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_expander.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

void main() {
  const expander = RecurrenceExpander();

  test('expands daily interval', () {
    final occurrences = expander.expand(
      rule: const RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 2,
        count: 3,
      ),
      seriesStart: DateTime.utc(2026, 9, 1, 9),
      from: DateTime.utc(2026, 9, 1),
      to: DateTime.utc(2026, 9, 10),
    );
    expect(occurrences.map((o) => o.startsAt.day), [1, 3, 5]);
  });

  test('expands weekly BYDAY', () {
    final occurrences = expander.expand(
      rule: const RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDay: ['MO', 'WE'],
        count: 4,
      ),
      seriesStart: DateTime.utc(2026, 9, 1, 10), // Tuesday
      from: DateTime.utc(2026, 9, 1),
      to: DateTime.utc(2026, 9, 20),
    );
    expect(occurrences.map((o) => o.startsAt.weekday).toList(), [
      DateTime.wednesday,
      DateTime.monday,
      DateTime.wednesday,
      DateTime.monday,
    ]);
  });

  test('yearly Feb 29 becomes Feb 28 in non-leap years', () {
    final occurrences = expander.expand(
      rule: const RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        count: 2,
      ),
      seriesStart: DateTime.utc(2024, 2, 29, 12),
      from: DateTime.utc(2024, 1, 1),
      to: DateTime.utc(2027, 1, 1),
    );
    expect(occurrences[0].startsAt, DateTime.utc(2024, 2, 29, 12));
    expect(occurrences[1].startsAt, DateTime.utc(2025, 2, 28, 12));
  });
}
