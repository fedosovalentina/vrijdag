import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';

void main() {
  test('timezone fallback is a non-empty id', () {
    final id = resolveDeviceTimezoneFallback();
    expect(id, isNotEmpty);
    expect(id == 'UTC' || id.contains('/'), isTrue);
  });

  test('birthday validates month and day', () {
    expect(
      () => Birthday(
        id: '1',
        userId: 'u',
        name: 'Ada',
        month: 13,
        day: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ).validate(),
      throwsArgumentError,
    );
    Birthday(
      id: '1',
      userId: 'u',
      name: 'Ada',
      month: 12,
      day: 10,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ).validate();
  });

  test('age is null without year and correct with year', () {
    final withoutYear = Birthday(
      id: '1',
      userId: 'u',
      name: 'Ada',
      month: 12,
      day: 10,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    expect(withoutYear.ageOn(DateTime(2026, 12, 11)), isNull);

    final withYear = Birthday(
      id: '1',
      userId: 'u',
      name: 'Ada',
      month: 12,
      day: 10,
      year: 2000,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    expect(withYear.ageOn(DateTime(2026, 12, 9)), 25);
    expect(withYear.ageOn(DateTime(2026, 12, 10)), 26);
  });

  test('29 Feb maps to 28 Feb in non-leap years', () {
    expect(
      Birthday.occurrenceDate(year: 2025, month: 2, day: 29),
      DateTime(2025, 2, 28),
    );
    expect(
      Birthday.occurrenceDate(year: 2024, month: 2, day: 29),
      DateTime(2024, 2, 29),
    );
  });
}
