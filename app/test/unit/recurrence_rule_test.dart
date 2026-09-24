import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

void main() {
  test('round-trips weekly RRULE with BYDAY', () {
    const rule = RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      interval: 2,
      byDay: ['MO', 'WE'],
      count: 5,
    );
    final encoded = rule.toRrule();
    expect(encoded, 'FREQ=WEEKLY;INTERVAL=2;COUNT=5;BYDAY=MO,WE');
    final parsed = RecurrenceRule.parse(encoded);
    expect(parsed.frequency, RecurrenceFrequency.weekly);
    expect(parsed.interval, 2);
    expect(parsed.count, 5);
    expect(parsed.byDay, ['MO', 'WE']);
  });

  test('rejects count and until together', () {
    expect(
      () => RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        count: 3,
        until: DateTime.utc(2026, 12, 1),
      ).validate(),
      throwsArgumentError,
    );
  });

  test('stores excluded dates in the existing rule text', () {
    const rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
    final encoded = encodeStoredRecurrence(rule, [
      DateTime(2026, 9, 8),
      DateTime(2026, 9, 15),
    ]);
    final stored = decodeStoredRecurrence(encoded);
    expect(stored.rule?.frequency, RecurrenceFrequency.daily);
    expect(stored.exdates, [DateTime(2026, 9, 8), DateTime(2026, 9, 15)]);
    expect(decodeStoredRecurrence('FREQ=WEEKLY').exdates, isEmpty);
  });

  test('parses RRULE prefix', () {
    final parsed = RecurrenceRule.parse('RRULE:FREQ=YEARLY');
    expect(parsed.frequency, RecurrenceFrequency.yearly);
  });
}
