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
      () => const Birthday(
        id: '1',
        userId: 'u',
        name: 'Ada',
        month: 13,
        day: 1,
      ).validate(),
      throwsArgumentError,
    );
    const Birthday(
      id: '1',
      userId: 'u',
      name: 'Ada',
      month: 12,
      day: 10,
    ).validate();
  });
}
